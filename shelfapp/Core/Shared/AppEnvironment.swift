import Observation

@MainActor
@Observable
final class AppEnvironment {
    let auth: AuthStore
    let products: ProductsStore
    let storages: StoragesStore
    let shoppingList: ShoppingListStore
    let notifications: NotificationsStore
    let profile: ProfileStore
    let storageDetail: StorageDetailStore
    let router: AppRouter
    let apiClient: APIClient

    init(
        auth: AuthStore,
        products: ProductsStore,
        storages: StoragesStore,
        shoppingList: ShoppingListStore,
        notifications: NotificationsStore,
        profile: ProfileStore,
        storageDetail: StorageDetailStore,
        router: AppRouter,
        apiClient: APIClient
    ) {
        self.auth = auth
        self.products = products
        self.storages = storages
        self.shoppingList = shoppingList
        self.notifications = notifications
        self.profile = profile
        self.storageDetail = storageDetail
        self.router = router
        self.apiClient = apiClient
    }

    static func live() -> AppEnvironment {
        let auth = AuthStore()
        let apiClient = APIClient(tokenStore: KeychainTokenStore())
        let router = AppRouter()
        Task { await apiClient.setLogoutHandler { auth.logout() } }
        return AppEnvironment(
            auth: auth,
            products: ProductsStore(),
            storages: StoragesStore(),
            shoppingList: ShoppingListStore(),
            notifications: NotificationsStore(),
            profile: ProfileStore(auth: auth),
            storageDetail: StorageDetailStore(),
            router: router,
            apiClient: apiClient
        )
    }

    static func preview() -> AppEnvironment {
        let tokenStore = InMemoryTokenStore()
        tokenStore.save("preview-token")
        let apiClient = APIClient(tokenStore: tokenStore)
        let auth = AuthStore(tokenStore: tokenStore)
        return AppEnvironment(
            auth: auth,
            products: ProductsStore(),
            storages: StoragesStore(),
            shoppingList: ShoppingListStore(),
            notifications: NotificationsStore(),
            profile: ProfileStore(auth: auth),
            storageDetail: StorageDetailStore(),
            router: AppRouter(),
            apiClient: apiClient
        )
    }
}
