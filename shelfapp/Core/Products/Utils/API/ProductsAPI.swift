import Foundation

struct ProductsAPI {
    private static let baseURL = "http://localhost:8080/api/products"
    
    static func fetchAll(token: String, search: String? = nil, page: Int = 0, size: Int? = nil) async throws -> PaginatedResponseDTO<ProductDTO> {
        var url = URL(string: baseURL)!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)")
        ]
        
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let size = size {
            queryItems.append(URLQueryItem(name: "size", value: "\(size)"))
        }
        
        components.queryItems = queryItems
        url = components.url!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(PaginatedResponseDTO<ProductDTO>.self, from: data)
    }
    
    static func fetchById(token: String, id: Int) async throws -> ProductDTO {
        let url = URL(string: "\(baseURL)/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(ProductDTO.self, from: data)
    }
    
    static func getCategories(token: String) async throws -> [String] {
        let url = URL(string: "\(baseURL)/categories")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode([String].self, from: data)
    }
    
    static func create(token: String, name: String, category: String, expirationDaysDelta: Int, description: String? = nil, barcode: String? = nil) async throws -> ProductDTO {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = CreateProductRequestDTO(
            name: name,
            description: description,
            category: category,
            barcode: barcode,
            expirationDaysDelta: expirationDaysDelta
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(ProductDTO.self, from: data)
    }
    
    static func update(token: String, id: Int, name: String? = nil, category: String? = nil, expirationDaysDelta: Int? = nil, description: String? = nil, barcode: String? = nil) async throws -> ProductDTO {
        let url = URL(string: "\(baseURL)/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = UpdateProductRequestDTO(
            name: name,
            description: description,
            category: category,
            barcode: barcode,
            expirationDaysDelta: expirationDaysDelta
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(ProductDTO.self, from: data)
    }
    
    static func delete(token: String, id: Int) async throws {
        let url = URL(string: "\(baseURL)/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
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
