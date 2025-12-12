//
//  AppError.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation

enum AppError: LocalizedError, Equatable {
    case auth(String)
    case firestore(String)
    case location(String)
    case pairing(String)
    case trip(String)
    case generic(String)
    
    var errorDescription: String? {
        switch self {
        case .auth(let message): return "Errore Autenticazione: \(message)"
        case .firestore(let message): return "Errore Database: \(message)"
        case .location(let message): return "Errore Posizione: \(message)"
        case .pairing(let message): return "Errore Collegamento: \(message)"
        case .trip(let message): return "Errore Viaggio: \(message)"
        case .generic(let message): return message
        }
    }
}
