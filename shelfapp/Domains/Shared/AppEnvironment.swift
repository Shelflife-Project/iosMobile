import Observation

@MainActor
@Observable
final class AppEnvironment {
    let http: HTTPClient
    let authAPI: AuthAPI
    let productAPI: ProductAPI
    let storageAPI: StorageAPI
    let profileAPI: ProfileAPI
    let shoppingListAPI: ShoppingListAPI
    let notificationsAPI: NotificationsAPI
    let storageDetailAPI: StorageDetailAPI

    let auth: AuthStore
    let products: ProductsStore
    let storages: StorageStore
    let shoppingList: ShoppingListStore
    let notifications: NotificationsStore
    let profile: ProfileStore
    let storageDetail: StorageDetailStore

    init() {
        let authService = AuthService.shared
        var authStore: AuthStore!
        let http = DefaultHTTPClient(tokenProvider: { authStore?.token })
        let authAPI = DefaultAuthAPI(http: http)
        let productAPI = DefaultProductAPI(http: http)
        let storageAPI = DefaultStorageAPI(http: http)
        let profileAPI = DefaultProfileAPI(http: http)
        let shoppingListAPI = DefaultShoppingListAPI(http: http)
        let notificationsAPI = DefaultNotificationsAPI(http: http)
        let storageDetailAPI = DefaultStorageDetailAPI(http: http)

        self.http = http
        self.authAPI = authAPI
        self.productAPI = productAPI
        self.storageAPI = storageAPI
        self.profileAPI = profileAPI
        self.shoppingListAPI = shoppingListAPI
        self.notificationsAPI = notificationsAPI
        self.storageDetailAPI = storageDetailAPI

        authStore = AuthStore(api: authAPI, authService: authService)
        self.auth = authStore
        self.products = ProductsStore(api: productAPI)
        self.storages = StorageStore(api: storageAPI)
        self.shoppingList = ShoppingListStore(api: shoppingListAPI)
        self.notifications = NotificationsStore(api: notificationsAPI)
        self.profile = ProfileStore(api: profileAPI)
        self.storageDetail = StorageDetailStore(api: storageDetailAPI)
    }
}
