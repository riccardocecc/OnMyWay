//
//  User.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth // <--- AGGIUNTO QUESTO IMPORT

struct User: Identifiable, Codable, Equatable {
    // MARK: - Properties
    let id: String // Corrisponde all'UID di Auth
    let displayName: String
    let email: String?
    let createdAt: Date
    
    // MARK: - Notification Tokens
    var fcmToken: String?
    var activityPushToken: String? // Token temporaneo per Live Activity
    
    // MARK: - Location Data
    var homeLocation: GeoPoint? // Usiamo GeoPoint di Firestore direttamente
    
    // MARK: - Partner Data (Denormalized)
    /// ID del partner collegato
    var partnerId: String?
    
    /// ID del documento Pair che lega i due utenti
    var pairId: String?
    
    /// Nome del partner (salvato qui per non fare query extra)
    var partnerDisplayName: String?
    
    /// Token FCM del partner (fondamentale per notifiche dirette)
    var partnerFcmToken: String?
    
    // MARK: - Computed Properties
    var isPaired: Bool {
        return partnerId != nil && pairId != nil
    }
    
    // MARK: - CodingKeys
    // Mappatura personalizzata per i nomi dei campi Firestore
    enum CodingKeys: String, CodingKey {
        case id = "uid" // Firestore field è 'uid', modello swift è 'id'
        case displayName
        case email
        case createdAt
        case fcmToken
        case activityPushToken
        case homeLocation
        case partnerId
        case pairId
        case partnerDisplayName
        case partnerFcmToken
    }
}

// MARK: - EXTENSION PER INIZIALIZZAZIONE DA AUTH (NUOVO)
extension User {
    /// Crea un utente OnMyWay partendo dai dati di Firebase Auth
    init(authData: FirebaseAuth.User) {
        self.id = authData.uid
        self.displayName = authData.displayName ?? "Utente"
        self.email = authData.email
        self.createdAt = Date()
        
        // I campi opzionali partono come nil
        self.fcmToken = nil
        self.activityPushToken = nil
        self.homeLocation = nil
        self.partnerId = nil
        self.pairId = nil
        self.partnerDisplayName = nil
        self.partnerFcmToken = nil
    }
}
