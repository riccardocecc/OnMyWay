//
//  AppDependencyContainer.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation
import SwiftUI

// MARK: - Dependency Container
/// Contenitore per la Dependency Injection.
/// Inizializza e mantiene in vita le istanze "Singleton" dei servizi e dei manager.
final class AppDependencyContainer {
    
    // MARK: - Data Layer
    let firestoreService: FirestoreService
    
    // MARK: - Managers
    let authManager: AuthManager
    let pairingManager: PairingManager
    let notificationManager: NotificationManager
    let locationManager: LocationManager
    let geofenceManager: GeofenceManager
    let tripManager: TripManager
    let tripStateRestorer: TripStateRestorer
    let activityManager: ActivityManager
    let functionsManager: FunctionsManager
    
    // MARK: - Initialization
    init() {
        // 1. Inizializza i servizi di base (Data Layer)
        self.firestoreService = FirestoreService()
        self.functionsManager = FunctionsManager()
        
        // 2. Inizializza i Manager (Core Logic)
        // L'ordine è importante se ci sono dipendenze tra manager
        
        self.authManager = AuthManager(firestoreService: firestoreService)
        
        self.notificationManager = NotificationManager(firestoreService: firestoreService)
        
        self.pairingManager = PairingManager(firestoreService: firestoreService,
                                             authManager: authManager)
        
        self.locationManager = LocationManager()
        
        self.geofenceManager = GeofenceManager()
        
        self.activityManager = ActivityManager()
        
        self.tripStateRestorer = TripStateRestorer(firestoreService: firestoreService)
        
        // TripManager è il più complesso e dipende da quasi tutti gli altri
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

// MARK: - Placeholders (STUBS)
// Aggiungi questi stub temporanei per evitare errori di compilazione
// finché non creeremo i file reali nella cartella Managers/ e Data/.


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
