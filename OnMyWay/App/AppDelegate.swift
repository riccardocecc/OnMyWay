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

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 1. Firebase è già configurato in OnMyWayApp.init(), quindi NON lo chiamiamo qui.
        
        // 2. Configurazione Delegati Notifiche (Serve per intercettare i token)
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        // 3. Richiesta preliminare (opzionale, meglio farla nella UI)
        application.registerForRemoteNotifications()
        
        print("📱 AppDelegate didFinishLaunching complete")
        return true
    }
    
    // MARK: - APNs Token Handling
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Collega il token APNs a Firebase
        Messaging.messaging().apnsToken = deviceToken
        print("📡 APNs Token registered")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Mostra notifiche anche con app aperta
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Gestione tocco notifica
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 Notification tapped")
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("🔥 Firebase Messaging Token aggiornato: \(fcmToken)")
        
        // Notifichiamo il resto dell'app che il token è cambiato
        NotificationCenter.default.post(name: Notification.Name("FCMTokenUpdated"), object: nil, userInfo: ["token": fcmToken])
    }
}
