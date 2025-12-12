//
//  OnboardingView.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI
import AuthenticationServices
import GoogleSignInSwift
// MARK: - Data Model for Carousel
struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentPage = 0
    
    // Dati del carosello
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "shield.check.fill",
            title: "Safety & Connection",
            description: "Condividi il tuo rientro a casa con chi ami, in totale sicurezza."
        ),
        OnboardingPage(
            image: "location.slash.fill",
            title: "Privacy First",
            description: "Nessun tracciamento 24/7. La posizione viene condivisa solo durante il viaggio attivo."
        ),
        OnboardingPage(
            image: "bell.badge.fill",
            title: "Live Updates",
            description: "Segui il progresso direttamente dalla Lock Screen e Dynamic Island."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Carousel Section
            TabView(selection: $currentPage) {
                foreachPage
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(maxHeight: .infinity)
            
            // MARK: - Footer / Actions
            VStack(spacing: 16) {
                            
                            // Bottone Google Nativo (o custom)
                            GoogleSignInButton(scheme: .dark, style: .wide, action: {
                                handleGoogleLogin()
                            })
                            .frame(height: 50)
                            .padding(.horizontal)
                            
                            // Nota: Abbiamo rimosso Apple ID e Guest Mode come richiesto
                            
                            Text("Continuando accetti i Termini di Servizio e la Privacy Policy.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .padding(.top, 20)
            .background(Color.brandBackground)
        }
        .background(Color.brandBackground.ignoresSafeArea())
    }
    
    // MARK: - Components
    
    private var foreachPage: some View {
        ForEach(pages.indices, id: \.self) { index in
            let page = pages[index]
            
            VStack(spacing: 24) {
                Spacer()
                
                // Icona animata
                Image(systemName: page.image)
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient.brandGradient
                    )
                    .symbolEffect(.bounce, value: currentPage == index)
                    .padding(.bottom, 20)
                
                // Testi
                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.appLargeTitle)
                        .foregroundStyle(Color.primary)
                    
                    Text(page.description)
                        .font(.appBody)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
            }
            .tag(index)
        }
    }
    
    // MARK: - Actions
    
    private func handleGoogleLogin() {
            Task {
                do {
                    // Nota: Inietta AuthManager nell'AppState o accedivi tramite il container
                    // Esempio ipotetico di chiamata:
                    // try await appState.loginWithGoogle()
                    
                    // Se non hai esposto il metodo in AppState, dovrai passarlo o accedervi sporcando un po' l'architettura per ora:
                    // await container.authManager.signInWithGoogle()
                    
                    // SIMULAZIONE CODICE PER COLLEGARE UI A MANAGER:
                    // Supponendo che tu abbia esposto `signInWithGoogle` in AppState:
                    try await appState.signInWithGoogle()
                    
                } catch {
                    print("❌ Errore Login Google: \(error.localizedDescription)")
                }
            }
        }
}

#Preview {
    // Inject mock AppState for preview
    let container = AppDependencyContainer()
    let state = AppState(container: container)
    return OnboardingView()
        .environment(state)
}
