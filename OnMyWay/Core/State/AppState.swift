//
//  AppState.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI
import Observation

/// Stato della connessione durante un viaggio attivo
enum TripConnectionState {
    /// Nessun viaggio in corso
    case idle
    /// Viaggio creato, in attesa che il partner avvii la Live Activity (Token Handshake)
    case waitingForPartnerToken
    /// Token ricevuto, loop aggiornamenti attivo
    case connected
    /// Connessione internet persa, aggiornamenti in coda
    case offline
}

@Observable
final class AppState {
    // MARK: - Dependencies
    private let container: AppDependencyContainer
    
    // MARK: - Authentication & User Data
    /// L'utente corrente con i dati del partner denormalizzati.
    /// Se nil, l'utente non è loggato.
    var currentUser: User? = nil
    
    /// Il partner collegato.
    /// Se nil, l'utente non ha ancora completato il pairing.
    var partner: User? = nil
    
    /// ID della relazione di coppia (documento `pairs/{pairId}`)
    var pairId: String? = nil
    
    // MARK: - Trip Data
    /// Il viaggio attivo dell'utente corrente (se sta viaggiando).
    var activeTrip: Trip? = nil
    
    /// Il viaggio attivo del partner (se il partner sta viaggiando).
    var partnerTrip: Trip? = nil
    
    /// Stato della connessione real-time per il viaggio attivo.
    var tripConnectionState: TripConnectionState = .idle
    
    // MARK: - System State
    /// Eventuali errori da mostrare all'utente (es. in un alert).
    var error: AppError? = nil
    
    /// Indica se l'app sta eseguendo un'operazione bloccante (es. login, creazione trip).
    var isLoading: Bool = false
    
    // MARK: - Computed Properties (UI Logic)
    
    /// True se l'utente è loggato.
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    /// True se l'utente ha un partner collegato.
    var isPaired: Bool {
        partner != nil
    }
    
    /// True se c'è un viaggio in corso (o mio o del partner).
    var hasActiveTrip: Bool {
        activeTrip != nil || partnerTrip != nil
    }
    
    /// Determina se il client può inviare aggiornamenti al partner.
    var canSendUpdates: Bool {
        tripConnectionState == .connected
    }
    
    // MARK: - Initialization
    
    init(container: AppDependencyContainer) {
        self.container = container
        setupBindings()
    }
    var pairingManager: PairingManager {
            return container.pairingManager
        }
    // MARK: - Setup & Recovery
    private var listeners = FirestoreListeners()
    private func setupBindings() {
        // In uno scenario reale, qui osserveremmo lo stream dell'AuthManager.
        // Poiché AuthManager aggiorna il suo stato internamente tramite il listener di Firebase,
        // per l'MVP sincronizziamo manualmente durante le azioni o usiamo restoreState.
    }
    
    /// Chiamato dopo il login per avviare il sync real-time
    func startRealtimeSync(for userId: String) {
            listeners.startListeningToUser(userId: userId) { [weak self] updatedUser in
                guard let self = self else { return }
                
                Task { @MainActor in
                    // 1. Aggiorna l'utente corrente con animazione
                    withAnimation {
                        self.currentUser = updatedUser
                    }
                    
                    // 2. Controlla e scarica il partner (FUORI da withAnimation perché è async)
                    if let partnerId = updatedUser.partnerId, self.partner == nil {
                        await self.fetchPartner(partnerId)
                    }
                }
            }
        }
        
        func stopRealtimeSync() {
            listeners.stopListening()
        }
        
    private func fetchPartner(_ partnerId: String) async {
            do {
                let partner: User = try await container.firestoreService.getDocument(path: "users", id: partnerId)
                await MainActor.run {
                    withAnimation { // <--- Aggiungi qui l'animazione
                        self.partner = partner
                    }
                }
            } catch {
                print("Errore fetch partner: \(error)")
            }
        }
    
    /// Tenta di ripristinare lo stato dell'app dopo un kill o un crash.
    func restoreState() async {
        do {
            isLoading = true
            defer { isLoading = false }
            
            // 1. Verifica sessione Auth (Google/Firebase)
            try await container.authManager.checkSession()
            
            // Sincronizziamo l'utente dall'AuthManager allo stato globale
            if let managerUser = container.authManager.user {
                self.currentUser = managerUser
                print("✅ Utente ripristinato: \(managerUser.displayName)")
            }
            
            // 2. Se loggato, tenta il ripristino del viaggio
            if isAuthenticated {
                let restoredTrip = try await container.tripStateRestorer.restoreActiveTrip()
                
                if let trip = restoredTrip {
                    self.activeTrip = trip
                    self.tripConnectionState = .connected
                    print("✅ Viaggio ripristinato: \(trip.id ?? "unknown")")
                }
            }
        } catch {
            print("⚠️ Errore durante il ripristino stato: \(error)")
        }
    }
    
    // MARK: - User Actions (Auth)
    
    /// Avvia il flusso di login con Google.
    /// Deve essere chiamato dal thread principale (MainActor).
    @MainActor
    func signInWithGoogle() async {
        do {
            isLoading = true
            
            // 1. Chiama il manager per il login (apre SFSafariViewController/Google App)
            try await container.authManager.signInWithGoogle()
            
            // 2. Aggiorna lo stato locale con l'utente appena loggato
            if let user = container.authManager.user {
                self.currentUser = user
            }
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = AppError.auth(error.localizedDescription)
            print("❌ Errore Login UI: \(error)")
        }
    }
    
    /// Effettua il logout pulendo tutto lo stato.
    func signOut() {
        Task {
            do {
                try await container.authManager.signOut()
                
                await MainActor.run {
                    // Pulisce tutto lo stato in memoria
                    self.currentUser = nil
                    self.partner = nil
                    self.activeTrip = nil
                    self.partnerTrip = nil
                    self.tripConnectionState = .idle
                    self.pairId = nil
                }
            } catch {
                self.error = AppError.auth(error.localizedDescription)
            }
        }
    }
    
    // MARK: - User Actions (Trip)
    // Aggiungeremo qui startTrip, stopTrip etc.
}
