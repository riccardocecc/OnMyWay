// Core/Models/AppError.swift

import Foundation

// 1. Aggiungi ", Identifiable" qui
enum AppError: LocalizedError, Equatable, Identifiable {
    case auth(String)
    case firestore(String)
    case location(String)
    case pairing(String)
    case trip(String)
    case generic(String)
    
    // 2. Aggiungi questa proprietà computed richiesta dal protocollo
    var id: String {
        // Usiamo la descrizione stessa come ID, oppure un UUID random
        return self.localizedDescription
    }
    
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
