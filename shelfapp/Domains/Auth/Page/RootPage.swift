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
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedTab: TabItem = .home
    @State private var isBootstrappingData = false
    @State private var hasBootstrappedData = false

    init() {}

    private var notificationsBadgeCount: Int {
        computeNotificationsBadgeCount(
            invites: environment.notifications.invites,
            runningLowItems: environment.notifications.runningLowItems,
            shoppingItems: environment.shoppingList.items
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
            if !environment.auth.hasCheckedSession && environment.auth.token != nil {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .appGradientBackground()
            } else if environment.auth.isLoggedIn && (!hasBootstrappedData || isBootstrappingData) {
                ProgressView("Loading your data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .appGradientBackground()
            } else if environment.auth.isLoggedIn {
                tabContent
            } else {
                AuthPage()
                    .environment(environment.auth)
            }
        }
        .task {
            await bootstrap()
        }
        .onChange(of: environment.auth.isLoggedIn) { _, isLoggedIn in
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
}

private extension RootPage {
    var tabContent: some View {
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
        .environment(environment.storages)
        .environment(environment.notifications)
        .environment(environment.shoppingList)
        .environment(environment.profile)
        .environment(environment.products)
        .environment(environment.storageDetail)
        .environment(environment.auth)
    }
}

private extension RootPage {
    func bootstrap(force: Bool = false) async {
        if environment.auth.token != nil && !environment.auth.hasCheckedSession {
            _ = await environment.auth.me()
        }

        environment.profile.sync(from: environment.auth)

        guard environment.auth.isLoggedIn else { return }

        if hasBootstrappedData && !force { return }

        isBootstrappingData = true
        defer {
            isBootstrappingData = false
            hasBootstrappedData = true
        }

        await environment.products.fetch()
        await environment.storages.fetch()
        await environment.shoppingList.fetchAggregated()
        await environment.notifications.fetchAll()
    }

    func clearStores() {
        environment.storages.storages = []
        environment.storages.errorMessage = nil

        environment.products.products = []
        environment.products.errorMessage = nil

        environment.shoppingList.items = []
        environment.shoppingList.errorMessage = nil

        environment.notifications.invites = []
        environment.notifications.runningLowItems = []
        environment.notifications.aboutToExpireItems = []
        environment.notifications.errorMessage = nil

        environment.storageDetail.members = []
        environment.storageDetail.errorMessage = nil
    }
}
