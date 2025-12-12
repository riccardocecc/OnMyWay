//
//  AppDelegate.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MARK: - App Delegate
/// Gestisce gli eventi del ciclo di vita dell'applicazione a livello di sistema (UIKit).
/// Responsabile per la configurazione di Firebase e delle Notifiche Push (APNs).
class AppDelegate: NSObject, UIApplicationDelegate {
    
    // Riferimento a NotificationManager per aggiornare il token
    // Nota: In un'architettura pura potremmo usare un Singleton o NotificationCenter,
    // qui usiamo un approccio semplice per l'MVP.
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 1. Configurazione Firebase
        FirebaseApp.configure()
        print("✅ Firebase Configured via AppDelegate")
        
        // 2. Configurazione Delegati Notifiche
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        // 3. Registrazione per notifiche remote
        // La richiesta di permesso all'utente verrà fatta poi nella UI (Onboarding),
        // ma qui prepariamo il sistema a ricevere il token.
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // MARK: - APNs Token Handling
    
    // Chiamato quando la registrazione APNs ha successo
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Passiamo il token APNs a Firebase Messaging.
        // Necessario per convertire il token APNs in token FCM o per l'auth via notifiche.
        Messaging.messaging().apnsToken = deviceToken
        
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📡 APNs Token received: \(tokenString)")
    }
    
    // Chiamato quando la registrazione APNs fallisce
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Gestisce come mostrare le notifiche quando l'app è in primo piano (Foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Per questo progetto, vogliamo mostrare le notifiche (banner/suono)
        // anche se l'utente sta usando l'app (es. "Partner è arrivato").
        completionHandler([.banner, .sound, .badge])
    }
    
    // Gestisce il tap sulla notifica
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("👆 Notification tapped with info: \(userInfo)")
        
        // Qui potremmo gestire il deep linking in futuro (es. aprire direttamente la mappa)
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate (Firebase)
extension AppDelegate: MessagingDelegate {
    
    // Chiamato quando il token FCM viene aggiornato/rigenerato
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        print("🔥 Firebase Messaging Token: \(fcmToken)")
        
        // Nota: L'aggiornamento di questo token su Firestore avverrà
        // tramite AuthManager/NotificationManager che osservano lo stato,
        // oppure possiamo postare una notifica interna qui.
        NotificationCenter.default.post(name: Notification.Name("FCMTokenUpdated"), object: nil, userInfo: ["token": fcmToken])
    }
}
