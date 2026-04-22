import Foundation
import UserNotifications

final class LocalNotificationService {
    static let shared = LocalNotificationService()

    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        do {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            }
        } catch {
            return
        }
    }

    func postShoppingListAddedNotification(productName: String, storageName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Shopping list updated"
        content.body = "\(productName) was added to \(storageName). Check your shopping list."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "shopping-add-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            return
        }
    }
}