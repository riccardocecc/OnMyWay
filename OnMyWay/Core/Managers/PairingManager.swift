//
//  PairingManager.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@Observable
class PairingManager {
    
    // MARK: - Dependencies
    private let db = Firestore.firestore()
    private let authManager: AuthManager
    
    // MARK: - State
    var isLoading = false
    var error: AppError? = nil
    
    // MARK: - Init
    init(firestoreService: FirestoreService, authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Generate Code (User A)
    
    /// Genera un codice casuale e lo salva su Firestore con scadenza
    func generatePairingCode() async throws -> String {
        guard let currentUser = authManager.user else {
            throw AppError.auth("Utente non autenticato")
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // 1. Genera codice numerico a 6 cifre
        let code = String(format: "%06d", Int.random(in: 0...999999))
        
        // 2. Prepara il modello
        let pairingCode = PairingCode(
            creatorId: currentUser.id,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(300) // 5 minuti di validità
        )
        
        // 3. Salva su Firestore
        // Usiamo il codice stesso come ID del documento per lookup veloce
        try await db.collection("pairingCodes").document(code).setData(from: pairingCode)
        
        return code
    }
    
    // MARK: - Complete Pairing (User B)
    
    /// Riceve il codice, valida e crea la connessione atomica
    func pairWith(code: String) async throws {
        guard let currentUser = authManager.user else {
            throw AppError.auth("Utente non autenticato")
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let codeRef = db.collection("pairingCodes").document(code)
        
        // 1. Leggi il codice
        let snapshot = try await codeRef.getDocument()
        guard let pairingCode = try? snapshot.data(as: PairingCode.self) else {
            throw AppError.pairing("Codice non valido o inesistente.")
        }
        
        // 2. Validazioni
        if !pairingCode.isValid {
            throw AppError.pairing("Il codice è scaduto.")
        }
        
        if pairingCode.creatorId == currentUser.id {
            throw AppError.pairing("Non puoi usare il tuo stesso codice.")
        }
        
        // 3. Recupera dati del Partner (Creator) per denormalizzazione
        let partnerSnapshot = try await db.collection("users").document(pairingCode.creatorId).getDocument()
        guard let partnerUser = try? partnerSnapshot.data(as: User.self) else {
            throw AppError.pairing("Utente partner non trovato.")
        }
        
        // 4. Prepara Batch Write (Atomica)
        let batch = db.batch()
        
        // A. Crea documento Pair
        let pairRef = db.collection("pairs").document()
        let newPair = Pair(
            user1Id: pairingCode.creatorId,
            user2Id: currentUser.id,
            createdAt: Date()
        )
        try batch.setData(from: newPair, forDocument: pairRef)
        
        // B. Aggiorna Creator (Partner)
        let creatorRef = db.collection("users").document(pairingCode.creatorId)
        batch.updateData([
            "partnerId": currentUser.id,
            "partnerDisplayName": currentUser.displayName,
            // Nota: partnerFcmToken verrà aggiornato dalle Cloud Functions o al prossimo avvio,
            // per ora mettiamo quello che abbiamo se disponibile
            "pairId": pairRef.documentID
        ], forDocument: creatorRef)
        
        // C. Aggiorna Me Stesso (Current User)
        let myRef = db.collection("users").document(currentUser.id)
        batch.updateData([
            "partnerId": partnerUser.id,
            "partnerDisplayName": partnerUser.displayName,
            "pairId": pairRef.documentID
        ], forDocument: myRef)
        
        // D. Elimina il codice usato
        batch.deleteDocument(codeRef)
        
        // 5. Esegui Commit
        try await batch.commit()
        print("✅ Pairing completato con successo!")
    }
}
