import Foundation

// MARK: - Shopping List Item DTO

struct ShoppingListItemDTO: Codable {
    let id: Int
    let storage: StorageDTO?
    let product: ProductDTO?
    let amountToBuy: Int

    func toDomain() -> ShoppingListItem {
        ShoppingListItem(storage: storage?.toDomain(), product: product?.toDomain(), amountToBuy: amountToBuy, serverId: id)
    }
}

// MARK: - Shopping List API Service

extension APIHelper {
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

    func fetchAggregatedShoppingItems() async throws -> [ShoppingListItem] {
        guard let url = normalizeURL("api/shoppinglist") else { throw APIError.invalidURL }

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

    func updateShoppingItemAmount(storageId: Int, itemId: Int, amountToBuy: Int) async throws -> ShoppingListItem {
        guard let url = normalizeURL("api/storages/\(storageId)/shoppinglist/\(itemId)") else { throw APIError.invalidURL }

        let payload: [String: Any] = [
            "amountToBuy": amountToBuy
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
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

    func completeShoppingItem(storageId: Int, itemId: Int) async throws {
        guard let url = normalizeURL("api/storages/\(storageId)/shoppinglist/\(itemId)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
}
