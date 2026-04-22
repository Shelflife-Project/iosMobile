import SwiftUI

enum AppTab: String, CaseIterable {
    case home = "Home"
    case notifications = "Notifications"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
        }
    }
}

@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var notificationsPath = NavigationPath()
    var profilePath = NavigationPath()
    var sheet: SheetRoute? = nil

    func handle(_ intent: NavigationIntent) {
        switch intent {
        case .runningLowAlert(let storageId, _):
            selectedTab = .notifications
            notificationsPath = NavigationPath()
            _ = storageId
        case .shoppingListItemAdded(let storageId):
            selectedTab = .home
            homePath.append(HomeRoute.storageDetail(id: storageId))
        case .openStorage(let id):
            selectedTab = .home
            homePath.append(HomeRoute.storageDetail(id: id))
        case .openNotifications:
            selectedTab = .notifications
        case .openShoppingList:
            selectedTab = .home
        }
    }
}
