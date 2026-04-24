import Foundation

protocol HTTPEndpoint {
    var path: String { get }
    var method: String { get }
    var queryItems: [URLQueryItem] { get }
    var body: AnyEncodable? { get }
    var rawBody: Data? { get }
    var contentType: String? { get }
}

extension HTTPEndpoint {
    var queryItems: [URLQueryItem] { [] }
    var body: AnyEncodable? { nil }
    var rawBody: Data? { nil }
    var contentType: String? { nil }

    func urlRequest(baseURL: URL = URL(string: AppConfig.baseURL)!) throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))

        if !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            guard let resolved = components?.url else {
                throw APIError.invalidURL
            }
            url = resolved
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let token = sharedJWTToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        if let rawBody = rawBody {
            request.httpBody = rawBody
        } else if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }
}
