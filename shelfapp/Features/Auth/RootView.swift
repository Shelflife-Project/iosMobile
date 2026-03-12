import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) var modelContext
    @State private var authManager = AuthManager.shared
    @State private var selectedTab: TabItem = .home
    @State private var isSyncing = false

    init() { 
        // Load stored token if available
        let storedToken = AuthService.shared.getStoredToken()
        APIService.shared.configure(
            baseURL: AppConfig.baseURL,
            token: storedToken
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

        // Verify the stored token is still valid before syncing
        if AuthService.shared.getStoredToken() != nil {
            do {
                let user = try await AuthService.shared.fetchCurrentUser()
                authManager.currentUser = user
            } catch {
                // Token is expired or invalid — force re-login
                print("Token validation failed: \(error.localizedDescription)")
                authManager.logout()
                isSyncing = false
                return
            }
        }

        do {
            // Sync products and storages from API
            try await SyncService.shared.syncProducts(in: modelContext)
            try await SyncService.shared.syncStorages(in: modelContext)
        } catch {
            print("Sync failed (using local data): \(error.localizedDescription)")
        }
        isSyncing = false
    }
}
