import SwiftUI

func computeNotificationsBadgeCount(
    invites: [PendingInviteInfo],
    runningLowItems: [RunningLowNotification],
    shoppingItems: [ShoppingListItem]
) -> Int {
    let unresolvedRunningLowCount = runningLowItems.filter { runningLow in
        !shoppingItems.contains { shoppingItem in
            shoppingItem.storage?.serverId == runningLow.storage.serverId
                && shoppingItem.product?.serverId == runningLow.product.serverId
        }
    }.count

    return invites.count + unresolvedRunningLowCount
}

struct RootView: View {
    @State private var authContext = AuthContext()
    @State private var selectedTab: TabItem = .home
    @State private var isBootstrappingData = false
    @State private var hasBootstrappedData = false
    @State private var notificationsContext = NotificationsContext()
    @State private var shoppingListContext = ShoppingListContext()
    @State private var profileContext = ProfileContext()
    @State private var productsContext = ProductsContext()
    @State private var storageDetailContext = StorageDetailContext()

    @State private var storageContext = StorageContext()

    init() {}

    private var notificationsBadgeCount: Int {
        computeNotificationsBadgeCount(
            invites: notificationsContext.invites,
            runningLowItems: notificationsContext.runningLowItems,
            shoppingItems: shoppingListContext.items
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
        Group {
            if !authContext.hasCheckedSession && authContext.token != nil {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .appGradientBackground()
            } else if authContext.isLoggedIn && (!hasBootstrappedData || isBootstrappingData) {
                ProgressView("Loading your data...")
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
                    .badge(notificationsBadgeCount == 0 ? nil : "\(notificationsBadgeCount)")
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
        .onChange(of: authContext.isLoggedIn) { _, isLoggedIn in
            if !isLoggedIn {
                clearContexts()
                hasBootstrappedData = false
                return
            }

            hasBootstrappedData = false
            Task {
                await bootstrap(force: true)
            }
        }
    }

    private func bootstrap(force: Bool = false) async {
        if authContext.token != nil && !authContext.hasCheckedSession {
            _ = await authContext.me()
        }

        profileContext.sync(from: authContext)

        guard authContext.isLoggedIn else { return }

        if hasBootstrappedData && !force { return }

        isBootstrappingData = true
        defer {
            isBootstrappingData = false
            hasBootstrappedData = true
        }

        await productsContext.fetch()
        await storageContext.fetch()
        await shoppingListContext.fetchAggregated()
        await notificationsContext.fetchAll()
    }

    private func clearContexts() {
        storageContext.storages = []
        storageContext.errorMessage = nil

        productsContext.products = []
        productsContext.errorMessage = nil

        shoppingListContext.items = []
        shoppingListContext.errorMessage = nil

        notificationsContext.invites = []
        notificationsContext.runningLowItems = []
        notificationsContext.aboutToExpireItems = []
        notificationsContext.errorMessage = nil

        storageDetailContext.members = []
        storageDetailContext.errorMessage = nil
    }
}
