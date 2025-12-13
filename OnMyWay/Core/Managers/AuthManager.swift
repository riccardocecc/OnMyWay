import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

@Observable
class AuthManager {

    private let firestoreService: FirestoreService
        // Aggiungiamo il riferimento diretto al DB per scrivere l'utente
    private let db = Firestore.firestore()
    // Pubblichiamo l'utente corrente per chi ascolta
    var user: User?
    
    init(firestoreService: FirestoreService) {
            self.firestoreService = firestoreService
            
            // Ascolta i cambiamenti di stato di Firebase Auth
            Auth.auth().addStateDidChangeListener { [weak self] _, firUser in
                if let firUser = firUser {
                    // NOTA: Qui aggiorniamo solo lo stato locale temporaneamente.
                    // I dati completi (es. partnerId) arriveranno dal listener su Firestore (che faremo dopo).
                    // Per ora usiamo i dati di Auth.
                    self?.user = User(authData: firUser)
                } else {
                    self?.user = nil
                }
            }
        }
    
    /// Gestisce il flusso di login con Google
    @MainActor
        func signInWithGoogle() async throws {
            // 1. Ottieni il root view controller (necessario per il popup di Google)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                throw AppError.auth("Impossibile trovare la finestra principale.")
            }
            
            // 2. Avvia il flusso GIDSignIn
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            // 3. Ottieni le credenziali
            // NOTA: idToken è opzionale, quindi va bene nel guard.
            guard let idToken = result.user.idToken?.tokenString else {
                throw AppError.auth("ID Token Google non valido.")
            }
            
            // NOTA: accessToken NON è opzionale nelle nuove versioni SDK, quindi lo assegniamo direttamente.
            let accessToken = result.user.accessToken.tokenString
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)
            
            // 4. Login su Firebase
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // 5. Opzionale: Salva utente su Firestore
            try await ensureUserDocumentExists(user: authResult.user)
            
            print("✅ Login Google riuscito: \(authResult.user.uid)")
        }
    
    func checkSession() async throws {
        // Firebase gestisce la sessione automaticamente, ma qui potremmo fare refresh del token
        if let currentUser = Auth.auth().currentUser {
             print("Sessione attiva per: \(currentUser.uid)")
        }
    }
    
    func signOut() async throws {
        try Auth.auth().signOut() // Logout Firebase
        GIDSignIn.sharedInstance.signOut() // Logout Google SDK
        self.user = nil
    }
    
    // MARK: - Private Helpers
        
        /// Verifica se l'utente esiste su Firestore. Se non esiste, crea il documento iniziale.
        private func ensureUserDocumentExists(user: FirebaseAuth.User) async throws {
            let userRef = db.collection("users").document(user.uid)
            
            // Leggiamo il documento
            let document = try await userRef.getDocument()
            
            if document.exists {
                print("ℹ️ Utente già presente nel DB.")
                // Opzionale: Aggiorna timestamp ultimo accesso o foto profilo se cambiata
            } else {
                print("🆕 Primo accesso! Creazione documento utente...")
                
                // Creiamo l'oggetto User usando l'extension che abbiamo aggiunto in User.swift
                let newUser = User(authData: user)
                
                // Salviamo su Firestore
                // try userRef.setData(from: newUser) gestisce automaticamente la codifica
                try userRef.setData(from: newUser)
                
                print("✅ Documento utente creato su Firestore!")
            }
        }
}
