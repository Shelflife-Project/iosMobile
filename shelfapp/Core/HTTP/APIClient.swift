import Foundation

// MARK: - APIClient

actor APIClient {
    private let baseURL: URL
    private let tokenStore: TokenStore
    private let session: URLSession
    private var onLogout: (@MainActor () -> Void)?

    init(
        baseURL: URL = URL(string: AppConfig.baseURL)!,
        tokenStore: TokenStore,
        session: URLSession = .shared,
        onLogout: (@MainActor () -> Void)? = nil
    ) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.session = session
        self.onLogout = onLogout
    }

    func setLogoutHandler(_ handler: @escaping @MainActor () -> Void) {
        onLogout = handler
    }

    // MARK: - Request (with 401 retry)

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(endpoint)
        return try await performWithRetry(request: request, endpoint: endpoint)
    }

    func requestVoid(_ endpoint: Endpoint) async throws {
        let request = try buildRequest(endpoint)
        let (_, response) = try await session.data(for: request)
        try mapError(response: response, data: Data())
    }

    func upload<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(endpoint)
        return try await performWithRetry(request: request, endpoint: endpoint)
    }

    // MARK: - Private

    private func buildRequest(_ endpoint: Endpoint) throws -> URLRequest {
        let path = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var url = baseURL.appendingPathComponent(path)

        if !endpoint.queryItems.isEmpty {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comps?.queryItems = endpoint.queryItems
            guard let resolved = comps?.url else { throw APIError.invalidURL }
            url = resolved
        }

        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method

        if endpoint.requiresAuth, let token = tokenStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let contentType = endpoint.contentType {
            req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let rawBody = endpoint.rawBody {
            req.httpBody = rawBody
        } else if let body = endpoint.body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        return req
    }

    private func performWithRetry<T: Decodable>(request: URLRequest, endpoint: Endpoint) async throws -> T {
        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 401, endpoint.requiresAuth {
            let refreshed = try await refreshToken()
            var retryRequest = request
            retryRequest.setValue("Bearer \(refreshed)", forHTTPHeaderField: "Authorization")
            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            if let retryHttp = retryResponse as? HTTPURLResponse, retryHttp.statusCode == 401 {
                await forceLogout()
                throw APIError.unauthorized
            }
            try mapError(response: retryResponse, data: retryData)
            return try decode(retryData)
        }

        try mapError(response: response, data: data)
        return try decode(data)
    }

    private func refreshToken() async throws -> String {
        guard let token = tokenStore.token else { throw APIError.unauthorized }
        let url = baseURL.appendingPathComponent("api/auth/refresh")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            await forceLogout()
            throw APIError.unauthorized
        }
        let dto = try JSONDecoder().decode(AuthResponseDTO.self, from: data)
        tokenStore.save(dto.token)
        return dto.token
    }

    private func forceLogout() async {
        let handler = onLogout
        await MainActor.run { handler?() }
    }

    private func mapError(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch http.statusCode {
        case 200...299: return
        case 401: throw APIError.unauthorized
        case 403: throw APIError.forbidden
        case 404: throw APIError.notFound
        case 409:
            let code = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error?.code ?? "CONFLICT"
            throw APIError.conflict(code: code)
        case 422:
            let fields = (try? JSONDecoder().decode(ValidationEnvelope.self, from: data))?.error?.fields ?? [:]
            throw APIError.validation(fields: fields)
        default:
            let msg = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error?.message
            if let msg { throw APIError.serverMessage(msg) }
            throw APIError.serverError(statusCode: http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        if T.self == EmptyResponse.self { return EmptyResponse() as! T }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}

// MARK: - Error envelope helpers

private struct ErrorEnvelope: Decodable {
    struct ErrorBody: Decodable {
        let code: String?
        let message: String?
    }
    let error: ErrorBody?
}

private struct ValidationEnvelope: Decodable {
    struct ErrorBody: Decodable {
        let fields: [String: String]?
    }
    let error: ErrorBody?
}
