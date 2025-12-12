//
//  Trip.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation
import FirebaseFirestore

enum TripStatus: String, Codable, Equatable {
    /// Viaggio creato, in attesa che il partner apra la notifica e invii il token
    case waitingForToken = "waiting_token"
    /// Viaggio attivo e tracciato
    case active = "active"
    /// Viaggio completato con successo (arrivato a casa)
    case arrived = "arrived"
    /// Viaggio annullato manualmente
    case cancelled = "cancelled"
}

struct Trip: Identifiable, Codable, Equatable {
    // MARK: - Properties
    /// ID del documento Firestore (generato automaticamente o UUID)
    @DocumentID var id: String?
    
    let travelerId: String
    let partnerId: String
    let pairId: String
    
    var status: TripStatus
    
    // MARK: - Location Data
    let startLocation: GeoPoint
    let destination: GeoPoint
    var currentLocation: GeoPoint
    
    // MARK: - Progress Data
    /// Progresso da 0.0 a 1.0
    var currentProgress: Double
    /// Orario stimato di arrivo
    var currentEta: Date
    
    // MARK: - Connection Data
    /// Token APNs della Live Activity del partner.
    /// Se nil, stiamo ancora aspettando l'handshake.
    var activityToken: String?
    
    // MARK: - Timestamps
    let startedAt: Date
    var completedAt: Date?
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case travelerId
        case partnerId
        case pairId
        case status
        case startLocation
        case destination
        case currentLocation
        case currentProgress
        case currentEta
        case activityToken
        case startedAt
        case completedAt
    }
}
