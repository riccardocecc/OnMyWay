//
//  PairingView.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI

struct PairingView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "link")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Collega il Partner")
                .font(.title)
            
            Text("Devi collegarti al tuo partner per usare l'app.")
                .multilineTextAlignment(.center)
                .padding()
            
            // Bottone Pairing Esistente
            Button("Simula Pairing (Debug)") {
                // Simuliamo il pairing
                // Nella realtà chiameremmo pairingManager
                var updatedUser = appState.currentUser
                updatedUser?.partnerId = "partner_456"
                updatedUser?.pairId = "pair_789"
                updatedUser?.partnerDisplayName = "Luigi"
                
                // Creiamo anche l'oggetto partner
                let partner = User(
                    id: "partner_456",
                    displayName: "Luigi",
                    email: nil,
                    createdAt: Date()
                )
                
                withAnimation {
                    appState.currentUser = updatedUser
                    appState.partner = partner
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            
            // --- NUOVO BOTTONE LOGOUT ---
            Button("Esci (Logout)") {
                appState.signOut()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding(.top, 10)
        }
        .padding() // Aggiunto padding generico al container
    }
}
