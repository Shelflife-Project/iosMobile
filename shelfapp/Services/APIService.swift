import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case unauthorized
    case notFound
    case serverError(statusCode: Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please log in"
        case .notFound:
            return "Resource not found"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

class APIService {
    static let shared = APIService()

    // Configuration
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

    private func buildHeaders() -> [String: String] {
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

    // MARK: - Storage API

    func fetchStorages() async throws -> [Storage] {
        guard let url = normalizeURL("api/storages") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([StorageDTO].self, from: data).map { $0.toDomain() }
    }

    func fetchStorage(id: Int) async throws -> Storage {
        guard let url = normalizeURL("api/storages/\(id)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(StorageDTO.self, from: data)
        return dto.toDomain()
    }

    func createStorage(name: String) async throws -> Storage {
        guard let url = normalizeURL("api/storages") else { throw APIError.invalidURL }

        let payload: [String: Any] = ["name": name]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(StorageDTO.self, from: data)
        return dto.toDomain()
    }

    func updateStorageName(id: Int, name: String) async throws -> Storage {
        guard let url = normalizeURL("api/storages/\(id)") else { throw APIError.invalidURL }

        let payload: [String: Any] = ["name": name]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(StorageDTO.self, from: data)
        return dto.toDomain()
    }

    func deleteStorage(id: Int) async throws {
        guard let url = normalizeURL("api/storages/\(id)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Product API

    func fetchProducts() async throws -> [Product] {
        guard let url = normalizeURL("api/products") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([ProductDTO].self, from: data).map { $0.toDomain() }
    }

    func createProduct(name: String, category: String, expirationDaysDelta: Int) async throws -> Product {
        guard let url = normalizeURL("api/products") else { throw APIError.invalidURL }

        let payload: [String: Any] = [
            "name": name,
            "category": category,
            "expirationDaysDelta": expirationDaysDelta
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(ProductDTO.self, from: data)
        return dto.toDomain()
    }

    // MARK: - Storage Item API

    func fetchStorageItems(storageId: Int) async throws -> [StorageItem] {
        guard let url = normalizeURL("api/storages/\(storageId)/items") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([StorageItemDTO].self, from: data).map { $0.toDomain() }
    }

    func addStorageItem(storageId: Int, productId: Int, expiresAt: Date?) async throws -> StorageItem {
        guard let url = normalizeURL("api/storages/\(storageId)/items") else { throw APIError.invalidURL }

        var payload: [String: Any] = ["productId": productId]
        if let expiresAt = expiresAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            payload["expiresAt"] = formatter.string(from: expiresAt)
        }
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(StorageItemDTO.self, from: data)
        return dto.toDomain()
    }

    func deleteStorageItem(storageId: Int, itemId: Int) async throws {
        guard let url = normalizeURL("api/storages/\(storageId)/items/\(itemId)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Shopping List API

    func fetchShoppingItems(storageId: Int) async throws -> [ShoppingListItem] {
        guard let url = normalizeURL("api/storages/\(storageId)/shoppinglist") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([ShoppingListItemDTO].self, from: data).map { $0.toDomain() }
    }

    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem {
        guard let url = normalizeURL("api/storages/\(storageId)/shoppinglist") else { throw APIError.invalidURL }

        let payload: [String: Any] = [
            "productId": productId,
            "amountToBuy": amountToBuy
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(ShoppingListItemDTO.self, from: data)
        return dto.toDomain()
    }

    func deleteShoppingItem(storageId: Int, itemId: Int) async throws {
        guard let url = normalizeURL("api/storages/\(storageId)/shoppinglist/\(itemId)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Storage Members API

    func fetchMembers(storageId: Int) async throws -> [StorageMemberInfo] {
        guard let url = normalizeURL("api/storages/\(storageId)/members") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dtos = try decoder.decode([StorageMemberDTO].self, from: data)
        return dtos.map {
            StorageMemberInfo(id: $0.id, userId: $0.user.id, username: $0.user.username, accepted: $0.accepted)
        }
    }

    func inviteMember(storageId: Int, email: String) async throws -> StorageMemberInfo {
        guard let url = normalizeURL("api/storages/\(storageId)/members") else { throw APIError.invalidURL }

        let payload: [String: Any] = ["email": email]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(StorageMemberDTO.self, from: data)
        return StorageMemberInfo(id: dto.id, userId: dto.user.id, username: dto.user.username, accepted: dto.accepted)
    }

    func removeMember(storageId: Int, userId: Int) async throws {
        guard let url = normalizeURL("api/storages/\(storageId)/members/\(userId)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Invites API

    func fetchPendingInvites() async throws -> [PendingInviteInfo] {
        guard let url = normalizeURL("api/storages/invites") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dtos = try decoder.decode([StorageMemberDTO].self, from: data)
        return dtos.map {
            PendingInviteInfo(
                id: $0.id,
                storageName: $0.storage?.name ?? "Unknown",
                storageId: $0.storage?.id ?? 0,
                invitedBy: $0.storage?.owner?.username ?? "Unknown"
            )
        }
    }

    func acceptInvite(inviteId: Int) async throws {
        guard let url = normalizeURL("api/storages/invites/\(inviteId)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    func declineInvite(inviteId: Int) async throws {
        guard let url = normalizeURL("api/storages/invites/\(inviteId)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - User API

    func updateUser(id: Int, username: String) async throws -> User {
        guard let url = normalizeURL("api/users/\(id)") else { throw APIError.invalidURL }

        let payload: [String: Any] = ["username": username]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(UserDTO.self, from: data)
        return dto.toDomain()
    }

    func uploadUserPfp(userId: Int, imageData: Data, fileName: String = "profile.jpg", mimeType: String = "image/jpeg") async throws {
        guard let url = normalizeURL("api/users/\(userId)/pfp") else { throw APIError.invalidURL }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        var headers: [String: String] = [:]
        if let token = token {
            headers["Authorization"] = "Bearer \(token)"
        }
        headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        request.allHTTPHeaderFields = headers

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Response Validation

    private func validateResponse(_ response: URLResponse) throws {
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
}

// MARK: - Data Transfer Objects (DTOs)

struct StorageDTO: Codable {
    let id: Int
    let name: String
    let owner: UserDTO?

    func toDomain() -> Storage {
        Storage(name: name, owner: owner?.toDomain(), serverId: id)
    }
}

struct UserDTO: Codable {
    let id: Int
    let username: String
    let admin: Bool

    func toDomain() -> User {
        User(username: username, admin: admin, serverId: id)
    }
}

// MARK: - Storage Member DTO

struct StorageMemberDTO: Codable {
    let id: Int
    let storage: StorageDTO?
    let user: UserDTO
    let accepted: Bool
}

/// Lightweight struct for member display (not a SwiftData model)
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

struct ProductDTO: Codable {
    let id: Int
    let ownerId: Int?
    let name: String
    let category: String
    let expirationDaysDelta: Int
    let barcode: String?

    func toDomain() -> Product {
        Product(name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode, serverId: id)
    }
}

struct StorageItemDTO: Codable {
    let id: Int
    let product: ProductDTO?
    let expiresAt: String?
    let createdAt: String

    func toDomain() -> StorageItem {
        var expiresAtDate: Date? = nil
        if let expiresAt = expiresAt {
            // Backend returns LocalDate as "yyyy-MM-dd"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            expiresAtDate = dateFormatter.date(from: expiresAt)
            // Fallback to ISO8601 if needed
            if expiresAtDate == nil {
                expiresAtDate = ISO8601DateFormatter().date(from: expiresAt)
            }
        }

        var createdAtDate: Date
        let isoFormatter = ISO8601DateFormatter()
        // Try with fractional seconds first
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = isoFormatter.date(from: createdAt) {
            createdAtDate = parsed
        } else {
            isoFormatter.formatOptions = [.withInternetDateTime]
            createdAtDate = isoFormatter.date(from: createdAt) ?? Date()
        }

        return StorageItem(product: product?.toDomain(), expiresAt: expiresAtDate, createdAt: createdAtDate, serverId: id)
    }
}

struct ShoppingListItemDTO: Codable {
    let id: Int
    let storage: StorageDTO?
    let product: ProductDTO?
    let amountToBuy: Int

    func toDomain() -> ShoppingListItem {
        ShoppingListItem(storage: storage?.toDomain(), product: product?.toDomain(), amountToBuy: amountToBuy, serverId: id)
    }
}
