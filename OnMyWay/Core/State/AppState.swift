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
    let container: AppDependencyContainer
    
    // MARK: - Authentication & User Data
    /// L'utente corrente con i dati del partner denormalizzati.
    /// Se nil, l'utente non è loggato.
    var currentUser: User? = nil
    
    /// Il partner collegato.
    /// Se nil, l'utente non ha ancora completato il pairing.
    var partner: User? = nil // Usiamo User anche per il partner (modello simmetrico)
    
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
    /// Basato sulla logica che se `partner` è popolato, il pairing è completo.
    var isPaired: Bool {
        partner != nil
    }
    
    /// True se c'è un viaggio in corso (o mio o del partner).
    /// Utile per decidere se mostrare la Home Dashboard o la ActiveTripView.
    var hasActiveTrip: Bool {
        activeTrip != nil || partnerTrip != nil
    }
    
    /// Determina se il client può inviare aggiornamenti al partner.
    /// Richiede che il token handshake sia completato e la rete sia disponibile.
    var canSendUpdates: Bool {
        tripConnectionState == .connected
    }
    
    // MARK: - Initialization
    
    init(container: AppDependencyContainer) {
        self.container = container
        
        // Configurazione dei listener iniziali
        setupBindings()
    }
    
    // MARK: - Setup & Recovery
    
    private func setupBindings() {
        // In futuro qui potremo osservare stream di dati,
        // per ora la sincronizzazione avviene tramite i metodi di action.
    }
    
    /// Tenta di ripristinare lo stato dell'app dopo un kill o un crash.
    /// Chiamato da OnMyWayApp.swift all'avvio.
    func restoreState() async {
        do {
            isLoading = true
            defer { isLoading = false }
            
            // 1. Verifica sessione Auth
            try await container.authManager.checkSession()
            
            // Sincronizza lo stato locale con quello del manager
            if let user = container.authManager.user {
                self.currentUser = user
                print("✅ Utente ripristinato: \(user.displayName)")
            }
            
            // 2. Se loggato, tenta il ripristino del viaggio
            if isAuthenticated {
                // TripStateRestorer verifica UserDefaults e Firestore
                let restoredTrip = try await container.tripStateRestorer.restoreActiveTrip()
                
                if let trip = restoredTrip {
                    self.activeTrip = trip
                    // Se recuperiamo un trip, assumiamo che siamo "connected" o "offline"
                    self.tripConnectionState = .connected
                    print("✅ Viaggio ripristinato: \(trip.id ?? "unknown")")
                }
            }
        } catch {
            print("⚠️ Errore durante il ripristino stato: \(error)")
            // Non blocchiamo l'app per un errore di restore, l'utente può ricominciare
        }
    }
    
    // MARK: - User Actions (Facade)
    
    func signInAnonymously() {
        isLoading = true
        
        Task {
            do {
                // 1. Chiamata asincrona al manager (non restituisce valore, aggiorna stato interno)
                try await container.authManager.signInAnonymously()
                
                // 2. Sincronizziamo lo stato su AppState (sul Main Actor)
                if let user = container.authManager.user {
                    self.currentUser = user
                    
                    // TODO: Verifica se dobbiamo recuperare dati del partner
                    // if let user { await fetchPartnerData(for: user) }
                }
                
                self.isLoading = false
                
            } catch {
                print("❌ Login Error: \(error.localizedDescription)")
                self.error = AppError.auth(error.localizedDescription)
                self.isLoading = false
            }
        }
    }
    
    /// Metodo helper per gestire il logout pulendo lo stato
    func signOut() {
        Task {
            do {
                try await container.authManager.signOut()
                
                await MainActor.run {
                    self.currentUser = nil
                    self.partner = nil
                    self.activeTrip = nil
                    self.partnerTrip = nil
                    self.tripConnectionState = .idle
                }
            } catch {
                self.error = AppError.auth(error.localizedDescription)
            }
        }
    }
}
