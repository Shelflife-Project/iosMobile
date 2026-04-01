//
//  shelfappApp.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 02. 22..
//

import SwiftUI
import UserNotifications

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct shelfappApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) var appDelegate
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some Scene {
        WindowGroup {
            RootPage()
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}
