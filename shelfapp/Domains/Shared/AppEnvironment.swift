import Observation

@MainActor
@Observable
final class AppEnvironment {
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
        let authHTTP = DefaultAuthHTTPClient(tokenProvider: { authStore?.token })
        let productsHTTP = DefaultProductsHTTPClient(tokenProvider: { authStore?.token })
        let storagesHTTP = DefaultStoragesHTTPClient(tokenProvider: { authStore?.token })
        let profileHTTP = DefaultProfileHTTPClient(tokenProvider: { authStore?.token })
        let shoppingListHTTP = DefaultShoppingListHTTPClient(tokenProvider: { authStore?.token })
        let notificationsHTTP = DefaultNotificationsHTTPClient(tokenProvider: { authStore?.token })
        let storageDetailHTTP = DefaultStorageDetailHTTPClient(tokenProvider: { authStore?.token })

        let authAPI = DefaultAuthAPI(http: authHTTP)
        let productAPI = DefaultProductAPI(http: productsHTTP)
        let storageAPI = DefaultStorageAPI(http: storagesHTTP)
        let profileAPI = DefaultProfileAPI(http: profileHTTP)
        let shoppingListAPI = DefaultShoppingListAPI(http: shoppingListHTTP)
        let notificationsAPI = DefaultNotificationsAPI(http: notificationsHTTP)
        let storageDetailAPI = DefaultStorageDetailAPI(http: storageDetailHTTP)

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
