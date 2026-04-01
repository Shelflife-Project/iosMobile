import Foundation

// MARK: - Shared DTOs and Structures

struct PaginatedResponseDTO<T: Codable>: Codable {
    let data: [T]
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let pageSize: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

struct PaginatedResult<T> {
    let items: [T]
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let pageSize: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

/// Lightweight struct for member display (not a model)
struct StorageMemberInfo: Identifiable {
    let id: Int
    let userId: Int
    let username: String
    let accepted: Bool
}

/// Lightweight struct for pending invite display
struct PendingInviteInfo: Identifiable {
    let id: Int
    let storageName: String
    let storageId: Int
    let invitedBy: String
}

struct RunningLowNotification: Identifiable, Hashable {
    struct Item: Identifiable, Hashable {
        let id: Int
        let productName: String
        let quantity: Int
    }

    let storageId: Int
    let storageName: String
    let items: [Item]

    var id: String {
        "\(storageId)"
    }
}

// MARK: - API Helper

class APIHelper {
    static let shared = APIHelper()

    var baseURL: String = AppConfig.baseURL
    private var token: String?

    // MARK: - Configuration Methods

    func configure(baseURL: String, token: String? = nil) {
        self.baseURL = baseURL
        self.token = token
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    // MARK: - Helper Methods

    func buildHeaders() -> [String: String] {
        var headers: [String: String] = ["Content-Type": "application/json"]
        if let token = token {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }

    func normalizeURL(_ path: String) -> URL? {
        var urlString = baseURL
        if !urlString.hasSuffix("/") {
            urlString += "/"
        }
        urlString += path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: urlString)
    }

    func appendQueryItems(to url: URL, items: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        components.queryItems = items
        return components.url
    }

    func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 400...499:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        case 500...:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - URL Builders for Resources

    func productIconURL(productId: Int) -> URL? {
        normalizeURL("api/products/\(productId)/icon/small")
    }

    func userProfilePictureURL(userId: Int) -> URL? {
        normalizeURL("api/users/\(userId)/pfp/small")
    }
}
