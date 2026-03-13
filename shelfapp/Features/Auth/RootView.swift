import SwiftUI

struct RootView: View {
    @State private var authContext = AuthContext()
    @State private var selectedTab: TabItem = .home
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
        Group {
            if !authContext.hasCheckedSession && authContext.token != nil {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .appGradientBackground()
            } else if authContext.isLoggedIn {
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
            } else {
                LoginView()
                    .environment(authContext)
            }
        }
        .task {
            await bootstrap()
        }
    }

    private func bootstrap() async {
        if authContext.token != nil && !authContext.hasCheckedSession {
            _ = await authContext.me()
        }

        profileContext.sync(from: authContext)

        guard authContext.isLoggedIn else { return }

        await productsContext.fetch()
        await storageContext.fetch()
        shoppingListContext.sync(from: storageContext.storages)
        await notificationsContext.fetchInvites()
    }
}
