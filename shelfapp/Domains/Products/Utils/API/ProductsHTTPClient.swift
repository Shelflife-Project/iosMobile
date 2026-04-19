import Foundation

protocol ProductsHTTPClient {
    func request<T: Decodable>(_ endpoint: ProductsEndpoint) async throws -> T
}

struct DefaultProductsHTTPClient: ProductsHTTPClient {
    private let core: HTTPClient

    init(baseURL: URL = URL(string: AppConfig.baseURL)!, tokenProvider: @escaping () -> String? = { nil }) {
        self.core = DefaultHTTPClient(baseURL: baseURL, tokenProvider: tokenProvider)
    }

    init(core: HTTPClient) {
        self.core = core
    }

    func request<T: Decodable>(_ endpoint: ProductsEndpoint) async throws -> T {
        try await core.request(endpoint)
    }
}
