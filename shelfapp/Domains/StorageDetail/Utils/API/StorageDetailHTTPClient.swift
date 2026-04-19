import Foundation

protocol StorageDetailHTTPClient {
    func request<T: Decodable>(_ endpoint: StorageDetailEndpoint) async throws -> T
}

struct DefaultStorageDetailHTTPClient: StorageDetailHTTPClient {
    private let core: HTTPClient

    init(baseURL: URL = URL(string: AppConfig.baseURL)!, tokenProvider: @escaping () -> String? = { nil }) {
        self.core = DefaultHTTPClient(baseURL: baseURL, tokenProvider: tokenProvider)
    }

    init(core: HTTPClient) {
        self.core = core
    }

    func request<T: Decodable>(_ endpoint: StorageDetailEndpoint) async throws -> T {
        try await core.request(endpoint)
    }
}
