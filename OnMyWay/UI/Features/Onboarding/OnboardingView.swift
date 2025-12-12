//
//  OnboardingView.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI
import AuthenticationServices

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
                // 1. Sign in with Apple (Nativo)
                SignInWithAppleButton(
                    onRequest: { request in
                        // Qui configureremo la richiesta (scope email/name)
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        handleAppleLogin(result)
                    }
                )
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // 2. Bottone Anonimo/Debug (Per l'MVP)
                Button(action: {
                                    appState.signInAnonymously()
                                }) {
                                    if appState.isLoading {
                                        ProgressView()
                                            .tint(.primary)
                                    } else {
                                        Text("Continua come Ospite")
                                    }
                                }
                                .buttonStyle(.secondaryAction)
                                .disabled(appState.isLoading)
                
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
    
    private func handleAppleLogin(_ result: Result<ASAuthorization, Error>) {
            // TODO: Implementare il login con Apple in AuthManager
            print("Apple Login non ancora collegato")
        }
}

#Preview {
    // Inject mock AppState for preview
    let container = AppDependencyContainer()
    let state = AppState(container: container)
    return OnboardingView()
        .environment(state)
}
