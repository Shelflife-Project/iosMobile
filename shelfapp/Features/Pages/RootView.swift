import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) var modelContext
    @State private var authManager = AuthManager.shared
    @State private var selectedTab: TabItem = .home
    @State private var isSyncing = false

    init() { 
        APIService.shared.configure(
            baseURL: "http://localhost:8080",
            token: nil
        )
    }

    enum TabItem: String, CaseIterable {
        case home = "Home"
        case storages = "Storages"
        case products = "Products"
        case notifications = "Notifications"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .storages: return "cube.box.fill"
            case .products: return "cube.fill"
            case .notifications: return "bell.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        if authManager.isAuthenticated {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label(TabItem.home.rawValue, systemImage: TabItem.home.icon)
                    }
                    .tag(TabItem.home)
                NotificationsView()
                    .tabItem {
                        Label(TabItem.notifications.rawValue, systemImage: TabItem.notifications.icon)
                    }
                    .tag(TabItem.notifications)

                ProfileView()
                    .tabItem {
                        Label(TabItem.profile.rawValue, systemImage: TabItem.profile.icon)
                    }
                    .tag(TabItem.profile)
            }
            .task {
                await syncData()
            }
        } else {
            LoginView()
        }
    }

    private func syncData() async {
        isSyncing = true
        do {
            // Attempt to sync storages from API
            try await SyncService.shared.syncStorages(in: modelContext)
        } catch {
            print("Sync failed (using local data): \(error.localizedDescription)")
        }
        isSyncing = false
    }
}
