import Foundation

struct StorageDetailAPI {
    private static let baseURL = "http://localhost:8080/api/storages"
    
    // Storage functions already exist in StoragesAPI, but we keep these for convenience
    static func fetchStorage(token: String, id: Int) async throws -> StorageDTO {
        let url = URL(string: "\(baseURL)/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(StorageDTO.self, from: data)
    }
    
    // Use StoragesAPI for these instead
    static func fetchMembers(token: String, storageId: Int) async throws -> [StorageMemberDTO] {
        return try await StoragesAPI.fetchMembers(token: token, storageId: storageId)
    }
    
    static func addItem(token: String, storageId: Int, productId: Int, expiresAt: String) async throws -> StorageItemDTO {
        return try await StoragesAPI.addItem(token: token, storageId: storageId, productId: productId, expiresAt: expiresAt)
    }
    
    static func deleteItem(token: String, storageId: Int, itemId: Int) async throws {
        return try await StoragesAPI.deleteItem(token: token, storageId: storageId, itemId: itemId)
    }
    
    static func inviteMember(token: String, storageId: Int, email: String) async throws -> StorageMemberDTO {
        return try await StoragesAPI.inviteMember(token: token, storageId: storageId, email: email)
    }
    
    static func removeMember(token: String, storageId: Int, userId: Int) async throws {
        return try await StoragesAPI.removeMember(token: token, storageId: storageId, userId: userId)
    }
    
    // Shopping List operations
    static func fetchShoppingItems(token: String, storageId: Int) async throws -> [ShoppingListItemDTO] {
        return try await ShoppingListAPI.fetchByStorage(token: token, storageId: storageId)
    }
    
    static func addShoppingItem(token: String, storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItemDTO {
        return try await ShoppingListAPI.addItem(token: token, storageId: storageId, productId: productId, amountToBuy: amountToBuy)
    }
    
    static func updateShoppingItem(token: String, storageId: Int, itemId: Int, amountToBuy: Int) async throws -> ShoppingListItemDTO {
        return try await ShoppingListAPI.updateItem(token: token, storageId: storageId, itemId: itemId, amountToBuy: amountToBuy)
    }
    
    static func deleteShoppingItem(token: String, storageId: Int, itemId: Int) async throws {
        return try await ShoppingListAPI.deleteItem(token: token, storageId: storageId, itemId: itemId)
    }
    
    static func addShoppingItemToStorage(token: String, storageId: Int, itemId: Int) async throws {
        return try await ShoppingListAPI.addItemToStorage(token: token, storageId: storageId, itemId: itemId)
    }
    
    private static func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch http.statusCode {
        case 200...299:
            return
        case 400:
            throw APIError.serverError(statusCode: 400)
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(statusCode: http.statusCode)
        }
    }
}
