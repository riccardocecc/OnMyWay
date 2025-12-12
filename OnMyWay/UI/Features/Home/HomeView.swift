//
//  HomeView.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let partnerName = appState.currentUser?.partnerDisplayName {
                    Text("Ciao! Il tuo partner è \(partnerName)")
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: {
                    // Placeholder per inizio viaggio
                    print("Start trip tapped")
                }) {
                    VStack {
                        Image(systemName: "house.fill")
                            .font(.system(size: 40))
                        Text("Torno a Casa")
                            .font(.title2)
                            .bold()
                    }
                    .frame(width: 200, height: 200)
                    .background(Color.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(radius: 10)
                }
                
                Spacer()
                
                Button("Logout (Debug)") {
                    appState.signOut()
                }
                .foregroundStyle(.red)
            }
            .navigationTitle("Home")
        }
    }
}
