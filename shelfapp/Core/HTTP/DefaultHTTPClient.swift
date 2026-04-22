import Foundation

struct DefaultHTTPClient: HTTPClient {
    let baseURL: URL
    let tokenProvider: () -> String?

    init(baseURL: URL = URL(string: AppConfig.baseURL)!, tokenProvider: @escaping () -> String? = { nil }) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
    }

    func request<T: Decodable, E: HTTPEndpoint>(_ endpoint: E) async throws -> T {
        var url = baseURL.appendingPathComponent(endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))

        if !endpoint.queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = endpoint.queryItems
            guard let resolved = components?.url else {
                throw APIError.invalidURL
            }
            url = resolved
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method

        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let contentType = endpoint.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let rawBody = endpoint.rawBody {
            request.httpBody = rawBody
        } else if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            break
        case 403:
            throw APIError.forbidden
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 400...599:
            throw APIError.serverError(statusCode: http.statusCode)
        default:
            throw APIError.serverError(statusCode: http.statusCode)
        }

        if T.self == EmptyResponse.self {
            if data.isEmpty { return EmptyResponse() as! T }
            if let empty = try? JSONDecoder().decode(EmptyResponse.self, from: data) {
                return empty as! T
            }
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}

struct EmptyResponse: Codable {}
