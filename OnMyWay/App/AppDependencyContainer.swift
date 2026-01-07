//
//  AppDependencyContainer.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation
import SwiftUI

final class AppDependencyContainer {
    
    // MARK: - Data Layer
    let firestoreService: FirestoreService
    
    // MARK: - Managers
    let authManager: AuthManager
    let pairingManager: PairingManager
    let locationManager: LocationManager
    let tripStateRestorer: TripStateRestorer // <--- AGGIUNTO
    
    init() {
        print("🏗️ Initializing AppDependencyContainer...")
        
        // 1. Services
        self.firestoreService = FirestoreService()
        
        // 2. Managers
        self.authManager = AuthManager(firestoreService: firestoreService)
        self.locationManager = LocationManager()
        
        // Inizializziamo il restorer passandogli il service
        self.tripStateRestorer = TripStateRestorer(firestoreService: firestoreService) // <--- AGGIUNTO
        
        self.pairingManager = PairingManager(firestoreService: firestoreService, authManager: authManager)

        print("✅ AppDependencyContainer initialized")
    }
}
