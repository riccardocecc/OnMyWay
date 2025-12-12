//
//  FirestoreService.swift
//  OnMyWay
//
//  Created by Gemini on 12/12/25.
//

import Foundation
import FirebaseFirestore

/// Servizio generico per le operazioni CRUD su Firestore.
/// Gestisce la codifica/decodifica dei modelli e le chiamate asincrone.
final class FirestoreService {
    
    private let db = Firestore.firestore()
    
    // MARK: - CRUD Operations
    
    /// Salva o sovrascrive un documento.
    /// - Parameters:
    ///   - path: Il percorso della collezione (es. "users")
    ///   - id: L'ID del documento (opzionale, se nil viene generato da Firestore)
    ///   - data: L'oggetto da salvare (deve conformarsi a Encodable)
    ///   - merge: Se true, aggiorna solo i campi forniti; se false, sovrascrive tutto.
    func setData<T: Encodable>(path: String, id: String? = nil, data: T, merge: Bool = false) async throws {
        let collection = db.collection(path)
        let document = id != nil ? collection.document(id!) : collection.document()
        
        try document.setData(from: data, merge: merge)
    }
    
    /// Recupera un singolo documento.
    func getDocument<T: Decodable>(path: String, id: String) async throws -> T {
        let document = try await db.collection(path).document(id).getDocument()
        
        guard document.exists else {
            throw AppError.firestore("Documento non trovato in \(path)/\(id)")
        }
        
        return try document.data(as: T.self)
    }
    
    /// Aggiorna campi specifici di un documento senza sovrascriverlo interamente.
    /// Utile per aggiornare solo lo status o la posizione.
    func updateFields(path: String, id: String, data: [String: Any]) async throws {
        try await db.collection(path).document(id).updateData(data)
    }
    
    /// Elimina un documento.
    func deleteDocument(path: String, id: String) async throws {
        try await db.collection(path).document(id).delete()
    }
    
    // MARK: - Real-time Listeners
    
    /// Osserva un documento in tempo reale e restituisce uno stream di aggiornamenti.
    func listenToDocument<T: Decodable>(path: String, id: String) -> AsyncThrowingStream<T?, Error> {
        return AsyncThrowingStream { continuation in
            let listener = db.collection(path).document(id).addSnapshotListener { snapshot, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    continuation.yield(nil) // Documento cancellato o non esistente
                    return
                }
                
                do {
                    let data = try snapshot.data(as: T.self)
                    continuation.yield(data)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            // Gestione della cancellazione dello stream
            continuation.onTermination = { @Sendable _ in
                listener.remove()
            }
        }
    }
}
