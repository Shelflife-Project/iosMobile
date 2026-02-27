import Foundation
import SwiftData

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
    var baseURL: String = "http://localhost:8080"
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

    private func normalizeURL(_ path: String) -> URL? {
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

    func fetchStorage(id: String) async throws -> Storage {
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

    func updateStorageName(id: String, name: String) async throws -> Storage {
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

    func deleteStorage(id: String) async throws {
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

    func fetchStorageItems(storageId: String) async throws -> [StorageItem] {
        guard let url = normalizeURL("api/storages/\(storageId)/items") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([StorageItemDTO].self, from: data).map { $0.toDomain() }
    }

    func addStorageItem(storageId: String, productId: String, expiresAt: Date?) async throws -> StorageItem {
        guard let url = normalizeURL("api/storages/\(storageId)/items") else { throw APIError.invalidURL }

        var payload: [String: Any] = ["productId": productId]
        if let expiresAt = expiresAt {
            payload["expiresAt"] = ISO8601DateFormatter().string(from: expiresAt)
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

    func deleteStorageItem(storageId: String, itemId: String) async throws {
        guard let url = normalizeURL("api/storages/\(storageId)/items/\(itemId)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Shopping List API

    func fetchShoppingItems(storageId: String) async throws -> [ShoppingListItem] {
        guard let url = normalizeURL("api/storages/\(storageId)/shopping-items") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([ShoppingListItemDTO].self, from: data).map { $0.toDomain() }
    }

    func addShoppingItem(storageId: String, productId: String, amountToBuy: Int) async throws -> ShoppingListItem {
        guard let url = normalizeURL("api/storages/\(storageId)/shopping-items") else { throw APIError.invalidURL }

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

    func deleteShoppingItem(storageId: String, itemId: String) async throws {
        guard let url = normalizeURL("api/storages/\(storageId)/shopping-items/\(itemId)") else { throw APIError.invalidURL }

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
        return dtos.filter { $0.accepted }.map {
            StorageMemberInfo(id: $0.id, userId: $0.user.id, username: $0.user.username, accepted: $0.accepted)
        }
    }

    func removeMember(storageId: Int, userId: Int) async throws {
        guard let url = normalizeURL("api/storages/\(storageId)/members/\(userId)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = buildHeaders()

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

struct ProductDTO: Codable {
    let id: Int
    let ownerId: Int?
    let name: String
    let category: String
    let expirationDaysDelta: Int
    let barcode: String?

    func toDomain() -> Product {
        Product(name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode)
    }
}

struct StorageItemDTO: Codable {
    let id: Int
    let product: ProductDTO?
    let expiresAt: String?
    let createdAt: String

    func toDomain() -> StorageItem {
        let dateFormatter = ISO8601DateFormatter()
        let expiresAtDate = expiresAt.flatMap { dateFormatter.date(from: $0) }
        let createdAtDate = dateFormatter.date(from: createdAt) ?? Date()

        return StorageItem(product: product?.toDomain(), expiresAt: expiresAtDate, createdAt: createdAtDate)
    }
}

struct ShoppingListItemDTO: Codable {
    let id: Int
    let storage: StorageDTO?
    let product: ProductDTO?
    let amountToBuy: Int

    func toDomain() -> ShoppingListItem {
        ShoppingListItem(storage: storage?.toDomain(), product: product?.toDomain(), amountToBuy: amountToBuy)
    }
}
