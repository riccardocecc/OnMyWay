//
//  FirestoreService.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

//
//  FirestoreService.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation
import FirebaseFirestore

/// Servizio generico per operazioni CRUD su Firestore.
/// Gestisce la serializzazione/deserializzazione automatica dei modelli Codable.
final class FirestoreService {
    
    private let db = Firestore.firestore()
    
    init() {
        // Opzionale: Configurazione settings Firestore
        let settings = FirestoreSettings()
        // La persistenza offline è abilitata di default su iOS, ma possiamo esplicitarla
        settings.isPersistenceEnabled = true
        db.settings = settings
    }
    
    // MARK: - WRITE (Create / Overwrite)
    
    /// Salva o sovrascrive un documento.
    /// - Parameters:
    ///   - collection: Il nome della collezione (es. "users")
    ///   - documentId: L'ID del documento.
    ///   - data: L'oggetto da salvare (deve conformarsi a Encodable).
    ///   - merge: Se true, aggiorna solo i campi presenti; se false, sovrascrive tutto.
    func setData<T: Encodable>(collection: String, documentId: String, data: T, merge: Bool = false) async throws {
        let ref = db.collection(collection).document(documentId)
        try await ref.setData(from: data, merge: merge)
    }
    
    // MARK: - READ (Single Document)
    
    /// Legge un singolo documento e lo converte nel tipo richiesto.
    /// - Parameters:
    ///   - collection: Il nome della collezione.
    ///   - documentId: L'ID del documento.
    /// - Returns: L'oggetto di tipo T popolato.
    func getDocument<T: Decodable>(collection: String, documentId: String) async throws -> T {
        let ref = db.collection(collection).document(documentId)
        let snapshot = try await ref.getDocument()
        
        return try snapshot.data(as: T.self)
    }
    
    // MARK: - UPDATE (Partial Fields)
    
    /// Aggiorna specifici campi di un documento senza sovrascriverlo tutto.
    /// Utile per aggiornare solo coordinate o status.
    /// - Parameters:
    ///   - collection: Il nome della collezione.
    ///   - documentId: L'ID del documento.
    ///   - fields: Dizionario chiave-valore con i campi da aggiornare.
    func updateData(collection: String, documentId: String, fields: [String: Any]) async throws {
        let ref = db.collection(collection).document(documentId)
        try await ref.updateData(fields)
    }
    
    // MARK: - DELETE
    
    /// Elimina un documento.
    func deleteDocument(collection: String, documentId: String) async throws {
        let ref = db.collection(collection).document(documentId)
        try await ref.delete()
    }
    
    // MARK: - HELPERS (References)
    
    /// Restituisce un riferimento a una collezione (utile per i Listener esterni).
    func collectionRef(_ collection: String) -> CollectionReference {
        return db.collection(collection)
    }
    
    /// Restituisce un riferimento a un documento (utile per i Listener esterni).
    func documentRef(collection: String, documentId: String) -> DocumentReference {
        return db.collection(collection).document(documentId)
    }
}
