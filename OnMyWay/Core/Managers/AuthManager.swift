//
//  AuthManager.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

//
//  AuthManager.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import Observation

enum AuthError: LocalizedError {
    case unknown
    case sessionExpired
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .unknown: return "Errore sconosciuto"
        case .sessionExpired: return "Sessione scaduta, effettua nuovamente il login"
        case .userNotFound: return "Utente non trovato nel database"
        }
    }
}

@Observable
final class AuthManager: NSObject {
    
    // MARK: - Dependencies
    private let firestoreService: FirestoreService
    
    // MARK: - State
    /// L'utente Firebase autenticato (livello Auth)
    var firebaseUser: FirebaseAuth.User?
    
    // MARK: - Initialization
    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
        super.init()
        
        // Ascolta i cambiamenti di stato dell'autenticazione (login/logout/app start)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.firebaseUser = user
            if user == nil {
                print("🔒 Utente disconnesso (Auth State Listener)")
            } else {
                print("🔓 Utente connesso: \(user!.uid) (Auth State Listener)")
            }
        }
    }
    
    // MARK: - Session Management
    
    /// Controlla se c'è una sessione attiva e recupera il profilo utente dal DB.
    /// Se l'utente è loggato in Auth ma non ha il documento su DB (es. errore precedente), lo crea.
    func checkSession() async throws -> User? {
        guard let currentUser = Auth.auth().currentUser else {
            return nil
        }
        
        self.firebaseUser = currentUser
        
        do {
            // Tentiamo di leggere l'utente da Firestore
            // getDocument è generico, capisce che deve restituire un 'User' dal contesto
            let user: User = try await firestoreService.getDocument(collection: "users", documentId: currentUser.uid)
            print("✅ Utente recuperato dal DB: \(user.displayName)")
            return user
        } catch {
            print("⚠️ Utente Auth presente ma documento DB mancante o errore: \(error)")
            // Fallback: proviamo a ricreare l'utente se manca
            return try await createOrUpdateUserInFirestore(authData: currentUser)
        }
    }
    
    /// Effettua il logout pulito.
    func signOut() async throws {
        try Auth.auth().signOut()
        self.firebaseUser = nil
    }
    
    // MARK: - Login Methods
    
    /// Esegue il login anonimo (Utile per test immediati o modalità ospite).
    func signInAnonymously() async throws -> User {
        let result = try await Auth.auth().signInAnonymously()
        self.firebaseUser = result.user
        return try await createOrUpdateUserInFirestore(authData: result.user)
    }
    
    // MARK: - Helper
    
    /// Crea o aggiorna il documento User su Firestore basandosi sui dati di Firebase Auth.
    /// Usa 'merge: true' per non sovrascrivere dati esistenti (come il partnerId).
    @discardableResult
    private func createOrUpdateUserInFirestore(authData: FirebaseAuth.User) async throws -> User {
        
        // Se è anonimo non ha nome, diamogliene uno provvisorio
        let displayName = authData.displayName ?? "Viaggiatore \(String(authData.uid.prefix(4)))"
        
        let user = User(
            id: authData.uid,
            displayName: displayName,
            email: authData.email,
            createdAt: Date()
            // Gli altri campi (partnerId, fcmToken, etc.) sono opzionali e iniziano nil
        )
        
        try await firestoreService.setData(collection: "users", documentId: user.id, data: user, merge: true)
        print("👤 Profilo utente salvato/aggiornato su Firestore")
        
        return user
    }
}
