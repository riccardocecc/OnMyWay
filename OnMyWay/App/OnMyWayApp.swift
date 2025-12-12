
import SwiftUI
import FirebaseCore
import GoogleSignIn// <--- Aggiungi import
@main
struct OnMyWayApp: App {
    // 1. Adapter per AppDelegate
    // Gestisce la configurazione iniziale di Firebase, APNs e State Restoration
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // 2. Container per Dependency Injection
    // Mantiene le istanze dei Manager (Auth, Location, Trip, etc.)
    private let container: AppDependencyContainer

    // 3. Single Source of Truth (Swift Observation)
    // L'oggetto centrale che guida tutta la UI dell'app
    @State private var appState: AppState

    init() {
        FirebaseApp.configure()
        // Inizializzazione delle dipendenze
        let container = AppDependencyContainer()
        self.container = container
        
        // Inizializzazione dello stato iniettando il container
        // Usiamo State(initialValue:) per assicurarci che l'istanza sia creata una sola volta
        self._appState = State(initialValue: AppState(container: container))
    }

    var body: some Scene {
            WindowGroup {
                AppRouter()
                    .environment(appState)
                    .task {
                        await appState.restoreState()
                    }
                    // Aggiungi questo modificatore per gestire il redirect di Google
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
            }
        }
}
