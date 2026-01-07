//
//  LocationManager.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 14/12/25.
//

import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject {
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    
    /// Espone l'ultima posizione nota (utile per la UI immediata)
    var lastLocation: CLLocation?
    
    /// Stato dei permessi (per aggiornare la UI se i permessi mancano)
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Stream asincrono per ricevere aggiornamenti di posizione in tempo reale
    /// Questo sarà consumato dal TripManager durante il loop di viaggio
    var locationStream: AsyncStream<CLLocation> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    private var continuation: AsyncStream<CLLocation>.Continuation?
    
    // MARK: - Initialization
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest // Default iniziale
        self.locationManager.distanceFilter = 10 // Notifica ogni 10 metri minimo
        
        // Configurazione Background (Cruciale per "On My Way")
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.showsBackgroundLocationIndicator = true // Pillola blu quando in uso
    }
    
    // MARK: - Public API
    
    /// Richiede i permessi all'utente
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        // Nota: Il permesso "Always" verrà richiesto automaticamente da iOS
        // se necessario quando si passa in background, o puoi richiederlo esplicitamente
        // in una fase successiva se vuoi usare funzionalità avanzate subito.
    }
    
    /// Avvia il tracciamento
    func startUpdatingLocation() {
        // Verifica permessi prima di iniziare
        guard locationManager.authorizationStatus == .authorizedAlways ||
              locationManager.authorizationStatus == .authorizedWhenInUse else {
            print("⚠️ Permessi Location mancanti, impossibile avviare.")
            return
        }
        
        locationManager.startUpdatingLocation()
        print("📍 Location updates started")
    }
    
    /// Ferma il tracciamento
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        print("🛑 Location updates stopped")
    }
    
    // MARK: - Adaptive Accuracy (Stub per Roadmap v1.1)
    // Come da specifiche, implementeremo qui la logica per cambiare accuracy
    // in base alla distanza da casa per risparmiare batteria.
    func setAccuracy(isNearHome: Bool) {
        if isNearHome {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        } else {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 1. Aggiorna stato locale
        self.lastLocation = location
        
        // 2. Invia allo stream (per TripManager)
        continuation?.yield(location)
        
        // Log debug (rimuovere in produzione o usare Logger)
        // print("📍 New Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        print("🔒 Location Authorization changed: \(manager.authorizationStatus.rawValue)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location Manager Error: \(error.localizedDescription)")
    }
}
