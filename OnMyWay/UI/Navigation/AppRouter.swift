//
//  AppRouter.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI

/// Il "semaforo" della navigazione.
/// Determina quale schermata radice mostrare in base allo stato dell'AppState.
struct AppRouter: View {
    // Recuperiamo lo stato globale iniettato nella OnMyWayApp
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Group {
            // 1. Check Autenticazione
            if appState.isAuthenticated {
                
                // 2. Check Pairing (Relazione)
                if appState.isPaired {
                    // Utente loggato E ha un partner -> FLUSSO PRINCIPALE
                    // Nota: HomeView gestirà internamente se mostrare la dashboard
                    // o la schermata "In Viaggio" (ActiveTripView)
                    HomeView()
                        .transition(.opacity)
                    
                } else {
                    // Utente loggato ma SENZA partner -> FLUSSO PAIRING
                    // Questa schermata appare solo la prima volta
                    PairingView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                }
                
            } else {
                // Utente non loggato -> ONBOARDING
                OnboardingView()
                    .transition(.opacity)
            }
        }
        // Applica un'animazione fluida quando cambia lo stato di root
        // (es. quando l'utente completa il login o il pairing)
        .animation(.easeInOut(duration: 0.4), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: appState.isPaired)
        .task(id: appState.currentUser?.id) {
                    // Se c'è un utente loggato...
                    if let userId = appState.currentUser?.id {
                        print("🔄 AppRouter: Avvio sync real-time per \(userId)")
                        // ...attiva l'ascolto continuo su Firestore
                        appState.startRealtimeSync(for: userId)
                    }
                }
    }
}
