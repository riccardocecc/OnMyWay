//
//  AppDependencyContainer.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation
import SwiftUI

// MARK: - Dependency Container
final class AppDependencyContainer {
    
    // MARK: - Data Layer
    let firestoreService: FirestoreService
    
    // MARK: - Managers
    let authManager: AuthManager
    // Gli altri manager sono ancora Stub o da implementare, ma se non hai creato i file reali
    // per loro, dovrai mantenere i LORO stub, ma rimuovere quelli di Firestore e Auth.
    
    // NOTA: Se non hai ancora creato i file per PairingManager, NotificationManager, etc.
    // devi mantenere le loro definizioni fittizie, ma RIMUOVERE FirestoreService e AuthManager
    // perché per quelli abbiamo creato i file veri.
    
    let pairingManager: PairingManager
    let notificationManager: NotificationManager
    let locationManager: LocationManager
    let geofenceManager: GeofenceManager
    let tripManager: TripManager
    let tripStateRestorer: TripStateRestorer
    let activityManager: ActivityManager
    let functionsManager: FunctionsManager
    
    init() {
        // 1. Inizializza i servizi reali
        self.firestoreService = FirestoreService()
        
        // 2. Inizializza AuthManager iniettando il servizio reale
        self.authManager = AuthManager(firestoreService: firestoreService)
        
        // --- STUB TEMPORANEI PER IL RESTO ---
        // Se non hai ancora i file reali per questi, usiamo le classi Stub definite sotto.
        self.functionsManager = FunctionsManager()
        self.notificationManager = NotificationManager(firestoreService: firestoreService)
        self.pairingManager = PairingManager(firestoreService: firestoreService, authManager: authManager)
        self.locationManager = LocationManager()
        self.geofenceManager = GeofenceManager()
        self.activityManager = ActivityManager()
        self.tripStateRestorer = TripStateRestorer(firestoreService: firestoreService)
        
        self.tripManager = TripManager(
            firestoreService: firestoreService,
            authManager: authManager,
            locationManager: locationManager,
            geofenceManager: geofenceManager,
            activityManager: activityManager,
            functionsManager: functionsManager,
            notificationManager: notificationManager
        )
        
        print("✅ AppDependencyContainer initialized")
    }
}

// MARK: - REMAINING STUBS
// Mantieni SOLO questi se non hai ancora creato i file reali corrispondenti.
// HO RIMOSSO FirestoreService e AuthManager da qui perché ora sono reali.

class FunctionsManager { init() {} }
class PairingManager { init(firestoreService: FirestoreService, authManager: AuthManager) {} }
class NotificationManager { init(firestoreService: FirestoreService) {} }
class LocationManager { init() {} }
class GeofenceManager { init() {} }
class ActivityManager { init() {} }
class TripStateRestorer {
    init(firestoreService: FirestoreService) {}
    func restoreActiveTrip() async throws -> Trip? { return nil }
}
class TripManager {
    init(firestoreService: FirestoreService,
         authManager: AuthManager,
         locationManager: LocationManager,
         geofenceManager: GeofenceManager,
         activityManager: ActivityManager,
         functionsManager: FunctionsManager,
         notificationManager: NotificationManager) {}
}
