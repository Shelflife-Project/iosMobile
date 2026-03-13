import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) var modelContext
    @State private var authContext = AuthContext()
    @State private var selectedTab: TabItem = .home
    @State private var isSyncing = false
    @State private var notificationsContext = NotificationsContext()
    @State private var shoppingListContext = ShoppingListContext()
    @State private var profileContext = ProfileContext()
    @State private var productsContext = ProductsContext()
    @State private var storageDetailContext = StorageDetailContext()

    @State private var storageContext = StorageContext()

    init() {}

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
        if authContext.isAuthenticated {
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
            .environment(storageContext)
            .environment(notificationsContext)
            .environment(shoppingListContext)
            .environment(profileContext)
            .environment(productsContext)
            .environment(storageDetailContext)
            .environment(authContext)
            .task {
                await syncData()
            }
        } else {
            LoginView()
                .environment(authContext)
        }
    }

    private func syncData() async {
        isSyncing = true

        // Verify stored session is still valid before syncing
        if authContext.isAuthenticated {
            let isSessionValid = await authContext.refreshCurrentUser()
            profileContext.sync(from: authContext)
            if !isSessionValid {
                isSyncing = false
                return
            }
        }

        await productsContext.fetch(context: modelContext)
        await storageContext.fetch(context: modelContext)
        shoppingListContext.loadLocal(context: modelContext)
        profileContext.sync(from: authContext)
        isSyncing = false
    }
}
