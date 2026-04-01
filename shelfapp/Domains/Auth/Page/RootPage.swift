import SwiftUI

func computeNotificationsBadgeCount(
    invites: [PendingInviteInfo],
    runningLowItems: [RunningLowNotification],
    shoppingItems: [ShoppingListItem]
) -> Int {
    let unresolvedRunningLowCount = runningLowItems.reduce(into: 0) { count, runningLow in
        let unresolvedItemsInStorage = runningLow.items.filter { lowItem in
            !shoppingItems.contains { shoppingItem in
                shoppingItem.storage?.serverId == runningLow.storageId
                    && shoppingItem.product?.serverId == lowItem.id
            }
        }.count
        count += unresolvedItemsInStorage
    }

    return invites.count + unresolvedRunningLowCount
}

struct RootPage: View {
    @State private var authStore = AuthStore()
    @State private var selectedTab: TabItem = .home
    @State private var isBootstrappingData = false
    @State private var hasBootstrappedData = false
    @State private var notificationsStore = NotificationsStore()
    @State private var shoppingListStore = ShoppingListStore()
    @State private var profileStore = ProfileStore()
    @State private var productsStore = ProductsStore()
    @State private var storageDetailStore = StorageDetailStore()

    @State private var storageStore = StorageStore()

    init() {}

    private var notificationsBadgeCount: Int {
        computeNotificationsBadgeCount(
            invites: notificationsStore.invites,
            runningLowItems: notificationsStore.runningLowItems,
            shoppingItems: shoppingListStore.items
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
            if !authStore.hasCheckedSession && authStore.token != nil {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .appGradientBackground()
            } else if authStore.isLoggedIn && (!hasBootstrappedData || isBootstrappingData) {
                ProgressView("Loading your data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .appGradientBackground()
            } else if authStore.isLoggedIn {
            TabView(selection: $selectedTab) {
                HomePage()
                    .tabItem {
                        Label(TabItem.home.rawValue, systemImage: TabItem.home.icon)
                    }
                    .tag(TabItem.home)
                NotificationsPage()
                    .tabItem {
                        Label(TabItem.notifications.rawValue, systemImage: TabItem.notifications.icon)
                    }
                    .badge(notificationsBadgeCount == 0 ? nil : "\(notificationsBadgeCount)")
                    .tag(TabItem.notifications)

                ProfilePage()
                    .tabItem {
                        Label(TabItem.profile.rawValue, systemImage: TabItem.profile.icon)
                    }
                    .tag(TabItem.profile)
            }
            .environment(storageStore)
            .environment(notificationsStore)
            .environment(shoppingListStore)
            .environment(profileStore)
            .environment(productsStore)
            .environment(storageDetailStore)
            .environment(authStore)
            } else {
                AuthPage()
                    .environment(authStore)
            }
        }
        .task {
            await bootstrap()
        }
        .onChange(of: authStore.isLoggedIn) { _, isLoggedIn in
            if !isLoggedIn {
                clearStores()
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
        if authStore.token != nil && !authStore.hasCheckedSession {
            _ = await authStore.me()
        }

        profileStore.sync(from: authStore)

        guard authStore.isLoggedIn else { return }

        if hasBootstrappedData && !force { return }

        isBootstrappingData = true
        defer {
            isBootstrappingData = false
            hasBootstrappedData = true
        }

        await productsStore.fetch()
        await storageStore.fetch()
        await shoppingListStore.fetchAggregated()
        await notificationsStore.fetchAll()
    }

    private func clearStores() {
        storageStore.storages = []
        storageStore.errorMessage = nil

        productsStore.products = []
        productsStore.errorMessage = nil

        shoppingListStore.items = []
        shoppingListStore.errorMessage = nil

        notificationsStore.invites = []
        notificationsStore.runningLowItems = []
        notificationsStore.aboutToExpireItems = []
        notificationsStore.errorMessage = nil

        storageDetailStore.members = []
        storageDetailStore.errorMessage = nil
    }
}
