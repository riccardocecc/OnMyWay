//
//  AuthManager.swift
//  OnMyWay
//
//  Created by Gemini on 12/12/25.
//

import Foundation
import FirebaseAuth
import AuthenticationServices

@Observable
final class AuthManager {
    // MARK: - Dependencies
    private let firestoreService: FirestoreService
    
    // MARK: - State
    /// L'utente Firestore corrente (sincronizzato con AppState tramite Observation)
    var user: User? = nil
    
    /// Stream per osservare i cambiamenti di stato dell'autenticazione Firebase
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
        
        // Inizializza l'ascolto dello stato di auth
        self.startAuthListener()
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Session Management
    
    /// Verifica se c'è un utente loggato e ricarica i suoi dati da Firestore.
    /// Chiamato all'avvio dell'app da AppState.restoreState().
    func checkSession() async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            self.user = nil
            return
        }
        
        // Se siamo autenticati su Firebase, recuperiamo il documento User corrispondente
        do {
            let userData: User = try await firestoreService.getDocument(path: "users", id: firebaseUser.uid)
            await MainActor.run {
                self.user = userData
            }
        } catch {
            print("⚠️ Utente Auth presente ma documento Firestore mancante o errore: \(error)")
            // In caso di inconsistenza, potremmo decidere di fare logout o ricreare l'utente
            // Per ora lasciamo l'errore propagare o gestiamo silenziosamente
            throw error
        }
    }
    
    private func startAuthListener() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            
            if firebaseUser == nil {
                Task { @MainActor in self.user = nil }
            }
            // Nota: Il caricamento dei dati utente avviene esplicitamente in checkSession o post-login
            // per evitare race conditions async in questo listener sincrono.
        }
    }
    
    func signOut() async throws {
        try Auth.auth().signOut()
        await MainActor.run {
            self.user = nil
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Esegue il login anonimo (Per Debug/MVP).
    /// Crea automaticamente il documento User su Firestore se non esiste.
    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        try await createOrUpdateUserDocument(authResult: result, isAnonymous: true)
    }
    
    // Nota: Il Sign in with Apple richiede un flow più complesso lato UI per ottenere nonce e token.
    // Qui predisponiamo il metodo che riceve le credenziali processate.
    // Per l'MVP useremo principalmente signInAnonymously o simuleremo AppleAuth se necessario.
    
    // MARK: - User Document Management
    
    /// Crea o aggiorna il documento User su Firestore dopo un login avvenuto con successo.
    private func createOrUpdateUserDocument(authResult: AuthDataResult, isAnonymous: Bool, name: String? = nil) async throws {
        let uid = authResult.user.uid
        let email = authResult.user.email
        
        // Nome di default se non fornito
        let displayName = name ?? (isAnonymous ? "Ospite" : "Utente")
        
        // Controlliamo se l'utente esiste già per non sovrascrivere dati importanti (come il partnerId)
        do {
            let existingUser: User = try await firestoreService.getDocument(path: "users", id: uid)
            // L'utente esiste, aggiorniamo solo in memoria
            await MainActor.run {
                self.user = existingUser
            }
            print("✅ Utente esistente recuperato: \(existingUser.id)")
            
        } catch {
            // L'utente non esiste (o errore lettura), creiamo un nuovo documento
            print("🆕 Creazione nuovo utente su Firestore...")
            
            let newUser = User(
                id: uid,
                displayName: displayName,
                email: email,
                createdAt: Date(),
                fcmToken: nil, // Verrà aggiornato dal NotificationManager
                activityPushToken: nil,
                homeLocation: nil,
                partnerId: nil,
                pairId: nil,
                partnerDisplayName: nil,
                partnerFcmToken: nil
            )
            
            try await firestoreService.setData(path: "users", id: uid, data: newUser)
            
            await MainActor.run {
                self.user = newUser
            }
        }
    }
}
