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
    
    
    init() {
        // 1. Inizializza i servizi reali
        self.firestoreService = FirestoreService()
        
        // 2. Inizializza AuthManager iniettando il servizio reale
        self.authManager = AuthManager(firestoreService: firestoreService)
        
        // --- STUB TEMPORANEI PER IL RESTO ---
      
        self.pairingManager = PairingManager(firestoreService: firestoreService, authManager: authManager)

       
        print("✅ AppDependencyContainer initialized")
    }
}

