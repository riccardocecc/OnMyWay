//
//  FirestoreListeners.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 13/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Gestisce l'ascolto in tempo reale dei documenti critici
class FirestoreListeners {
    
    private let db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    
    /// Inizia ad ascoltare i cambiamenti sul documento dell'utente corrente.
    /// Fondamentale per rilevare quando il pairing viene completato dall'altro utente.
    func startListeningToUser(userId: String, onUpdate: @escaping (User) -> Void) {
        // Rimuovi listener precedente se esiste
        stopListening()
        
        print("🎧 Avvio listener su users/\(userId)")
        
        userListener = db.collection("users").document(userId)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, snapshot.exists,
                      let user = try? snapshot.data(as: User.self) else {
                    print("⚠️ Errore o documento utente nullo nel listener")
                    return
                }
                
                // Notifica l'app del cambiamento
                print("🔄 User Data Updated: isPaired = \(user.isPaired)")
                onUpdate(user)
            }
    }
    
    func stopListening() {
        userListener?.remove()
        userListener = nil
    }
}
