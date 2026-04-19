import Foundation

protocol NotificationsHTTPClient {
    func request<T: Decodable>(_ endpoint: NotificationsEndpoint) async throws -> T
}

struct DefaultNotificationsHTTPClient: NotificationsHTTPClient {
    private let core: HTTPClient

    init(baseURL: URL = URL(string: AppConfig.baseURL)!, tokenProvider: @escaping () -> String? = { nil }) {
        self.core = DefaultHTTPClient(baseURL: baseURL, tokenProvider: tokenProvider)
    }

    init(core: HTTPClient) {
        self.core = core
    }

    func request<T: Decodable>(_ endpoint: NotificationsEndpoint) async throws -> T {
        try await core.request(endpoint)
    }
}
