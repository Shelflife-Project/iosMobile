protocol HTTPClient {
    func request<T: Decodable, E: HTTPEndpoint>(_ endpoint: E) async throws -> T
}

