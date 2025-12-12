//
//  PairingCode.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//
import Foundation
import FirebaseFirestore

struct PairingCode: Identifiable, Codable {
    @DocumentID var id: String? // Il codice stesso è l'ID del documento (es. "482910")
    
    let creatorId: String
    let createdAt: Date
    let expiresAt: Date
    
    var isValid: Bool {
        return expiresAt > Date()
    }
}
