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
            Task { await bootstrap(force: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in }
    }
}

// MARK: - Tab content

private extension RootPage {
    @ViewBuilder
    var tabContent: some View {
        @Bindable var router = environment.router
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                HomePage()
            }
            .tabItem { Label(AppTab.home.rawValue, systemImage: AppTab.home.icon) }
            .tag(AppTab.home)

            NavigationStack(path: $router.notificationsPath) {
                NotificationsPage()
            }
            .tabItem { Label(AppTab.notifications.rawValue, systemImage: AppTab.notifications.icon) }
            .badge(notificationsBadgeCount == 0 ? nil : "\(notificationsBadgeCount)")
            .tag(AppTab.notifications)

            NavigationStack(path: $router.profilePath) {
                ProfilePage()
            }
            .tabItem { Label(AppTab.profile.rawValue, systemImage: AppTab.profile.icon) }
            .tag(AppTab.profile)
        }
        .environment(environment.storages)
        .environment(environment.notifications)
        .environment(environment.shoppingList)
        .environment(environment.profile)
        .environment(environment.products)
        .environment(environment.storageDetail)
        .environment(environment.auth)
        .environment(environment.router)
    }
}

// MARK: - Bootstrap

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
        environment.storages.storagesState = .idle
        environment.products.productsState = .idle
        environment.shoppingList.itemsState = .idle
        environment.notifications.notificationsState = .idle
        environment.storageDetail.membersState = .idle
        environment.storageDetail.itemsState = .idle
    }
}
