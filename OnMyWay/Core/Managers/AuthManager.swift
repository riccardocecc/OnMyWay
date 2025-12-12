import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import SwiftUI

@Observable
class AuthManager {
    private let firestoreService: FirestoreService
    
    // Pubblichiamo l'utente corrente per chi ascolta
    var user: User?
    
    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
        
        // Ascolta i cambiamenti di stato di Firebase Auth
        Auth.auth().addStateDidChangeListener { [weak self] _, firUser in
            if let firUser = firUser {
                // Mappiamo l'utente Firebase nel nostro modello User
                // Nota: In un caso reale dovremmo fare una fetch su Firestore per prendere gli altri dati
                self?.user = User(
                    id: firUser.uid,
                    displayName: firUser.displayName ?? "Utente Google",
                    email: firUser.email,
                    createdAt: Date(),
                    fcmToken: nil // Verrà aggiornato dal NotificationManager
                )
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
            // try await firestoreService.saveUser(authResult.user)
            
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
}
