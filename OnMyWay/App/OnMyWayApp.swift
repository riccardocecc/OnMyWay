//
//  OnMyWayApp.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct OnMyWayApp: App {
    // 1. Adapter per AppDelegate (Gestione notifiche)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // 2. Container e Stato
    // Non usiamo @State o init complessi qui per evitare race conditions,
    // inizializziamo tutto nel blocco init() in ordine preciso.
    private let container: AppDependencyContainer
    @State private var appState: AppState

    init() {
        // A. CONFIGURAZIONE FIREBASE (Deve essere la prima cosa in assoluto)
        FirebaseApp.configure()
        
        // B. Inizializzazione delle dipendenze (Ora Firestore è sicuro da usare)
        let container = AppDependencyContainer()
        self.container = container
        
        // C. Inizializzazione dello stato
        self._appState = State(initialValue: AppState(container: container))
        
        print("🚀 OnMyWayApp Initialized")
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(appState)
                .task {
                    // Ripristino stato (es. se l'app è stata killata durante un viaggio)
                    await appState.restoreState()
                }
                .onOpenURL { url in
                    // Gestione redirect login Google
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
