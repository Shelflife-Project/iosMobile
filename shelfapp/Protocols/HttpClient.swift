protocol HTTPClient {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

