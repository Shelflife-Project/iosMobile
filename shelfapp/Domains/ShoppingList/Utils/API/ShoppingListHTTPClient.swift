import Foundation

protocol ShoppingListHTTPClient {
    func request<T: Decodable>(_ endpoint: ShoppingListEndpoint) async throws -> T
}

struct DefaultShoppingListHTTPClient: ShoppingListHTTPClient {
    private let core: HTTPClient

    init(baseURL: URL = URL(string: AppConfig.baseURL)!, tokenProvider: @escaping () -> String? = { nil }) {
        self.core = DefaultHTTPClient(baseURL: baseURL, tokenProvider: tokenProvider)
    }

    init(core: HTTPClient) {
        self.core = core
    }

    func request<T: Decodable>(_ endpoint: ShoppingListEndpoint) async throws -> T {
        try await core.request(endpoint)
    }
}
