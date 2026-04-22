import Foundation

struct ShoppingListAPI {
    private static let baseURL = "http://localhost:8080/api"
    
    static func fetchAggregated(token: String) async throws -> [ShoppingListItemDTO] {
        let url = URL(string: "\(baseURL)/shoppinglist")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode([ShoppingListItemDTO].self, from: data)
    }
    
    static func fetchByStorage(token: String, storageId: Int) async throws -> [ShoppingListItemDTO] {
        let url = URL(string: "\(baseURL)/storages/\(storageId)/shoppinglist")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode([ShoppingListItemDTO].self, from: data)
    }
    
    static func addItem(token: String, storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItemDTO {
        let url = URL(string: "\(baseURL)/storages/\(storageId)/shoppinglist")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = CreateShoppingItemRequestDTO(productId: productId, amountToBuy: amountToBuy)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(ShoppingListItemDTO.self, from: data)
    }
    
    static func updateItem(token: String, storageId: Int, itemId: Int, amountToBuy: Int) async throws -> ShoppingListItemDTO {
        let url = URL(string: "\(baseURL)/storages/\(storageId)/shoppinglist/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = EditShoppingItemRequestDTO(amountToBuy: amountToBuy)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(ShoppingListItemDTO.self, from: data)
    }
    
    static func deleteItem(token: String, storageId: Int, itemId: Int) async throws {
        let url = URL(string: "\(baseURL)/storages/\(storageId)/shoppinglist/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
    
    static func addItemToStorage(token: String, storageId: Int, itemId: Int) async throws {
        let url = URL(string: "\(baseURL)/storages/\(storageId)/shoppinglist/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
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
