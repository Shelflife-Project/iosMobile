import Foundation

enum APIRequestClient {
    static func send<T: Decodable>(_ request: URLRequest) async throws -> T {
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