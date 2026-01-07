//
//  TripStateRestorer.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 14/12/25.
//

import Foundation
import FirebaseFirestore

final class TripStateRestorer {
    
    private let firestoreService: FirestoreService
    private let defaults = UserDefaults.standard
    private let kActiveTripIdKey = "active_trip_id"
    
    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }
    
    /// Tenta di recuperare un viaggio attivo salvato localmente
    func restoreActiveTrip() async throws -> Trip? {
        // 1. Controlliamo se abbiamo un ID salvato in locale
        guard let tripId = defaults.string(forKey: kActiveTripIdKey) else {
            return nil
        }
        
        print("🔄 Trovato ID viaggio attivo: \(tripId), recupero da Firestore...")
        
        do {
            // 2. Recuperiamo il documento fresco da Firestore
            let trip: Trip = try await firestoreService.getDocument(path: "trips", id: tripId)
            
            // 3. Verifichiamo che sia ancora valido (non terminato o cancellato)
            if trip.status == .arrived || trip.status == .cancelled {
                print("⚠️ Il viaggio recuperato è già terminato. Pulizia locale.")
                clearActiveTrip()
                return nil
            }
            
            return trip
            
        } catch {
            print("❌ Errore recupero viaggio: \(error)")
            // Se il documento non esiste più (es. cancellato manualmente), puliamo
            // TODO: Gestire meglio gli errori specifici di Firestore
            return nil
        }
    }
    
    /// Salva l'ID del viaggio corrente (da chiamare quando inizi un viaggio)
    func saveActiveTrip(id: String) {
        defaults.set(id, forKey: kActiveTripIdKey)
    }
    
    /// Pulisce lo stato (da chiamare quando il viaggio finisce)
    func clearActiveTrip() {
        defaults.removeObject(forKey: kActiveTripIdKey)
    }
}
