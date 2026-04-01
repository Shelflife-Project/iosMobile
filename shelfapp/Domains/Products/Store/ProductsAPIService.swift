import Foundation

// MARK: - Product DTO

struct ProductDTO: Codable {
    let id: Int
    let ownerId: Int?
    let name: String
    let category: String
    let expirationDaysDelta: Int
    let barcode: String?

    func toDomain() -> Product {
        Product(name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode, ownerId: ownerId, serverId: id)
    }
}

// MARK: - Products API Service

extension APIHelper {
    func fetchProductsPage(search: String = "", size: Int = 0, page: Int = 0) async throws -> PaginatedResult<Product> {
        guard let baseURL = normalizeURL("api/products") else { throw APIError.invalidURL }

        var queryItems = [URLQueryItem(name: "search", value: search)]
        if size > 0 {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
            queryItems.append(URLQueryItem(name: "size", value: String(size)))
        }

        guard let url = appendQueryItems(to: baseURL, items: queryItems) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        if let pageResult = try? decoder.decode(PaginatedResponseDTO<ProductDTO>.self, from: data) {
            return PaginatedResult(
                items: pageResult.data.map { $0.toDomain() },
                currentPage: pageResult.currentPage,
                totalPages: pageResult.totalPages,
                totalItems: pageResult.totalItems,
                pageSize: pageResult.pageSize,
                hasNext: pageResult.hasNext,
                hasPrevious: pageResult.hasPrevious
            )
        }

        let fallbackItems = try decoder.decode([ProductDTO].self, from: data).map { $0.toDomain() }
        return PaginatedResult(
            items: fallbackItems,
            currentPage: 0,
            totalPages: 1,
            totalItems: fallbackItems.count,
            pageSize: fallbackItems.count,
            hasNext: false,
            hasPrevious: false
        )
    }

    func fetchProducts() async throws -> [Product] {
        try await fetchProductsPage().items
    }

    func createProduct(name: String, category: String, expirationDaysDelta: Int, barcode: String?) async throws -> Product {
        guard let url = normalizeURL("api/products") else { throw APIError.invalidURL }

        let payload: [String: Any] = [
            "name": name,
            "category": category,
            "expirationDaysDelta": expirationDaysDelta,
            "barcode": barcode as Any
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

    func updateProduct(id: Int, name: String, category: String, expirationDaysDelta: Int, barcode: String?) async throws -> Product {
        guard let url = normalizeURL("api/products/\(id)") else { throw APIError.invalidURL }

        let payload: [String: Any] = [
            "name": name,
            "category": category,
            "expirationDaysDelta": expirationDaysDelta,
            "barcode": barcode as Any
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(ProductDTO.self, from: data)
        return dto.toDomain()
    }

    func deleteProduct(id: Int) async throws {
        guard let url = normalizeURL("api/products/\(id)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

}
