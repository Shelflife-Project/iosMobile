import Foundation

struct StoragesAPI {
    private static let baseURL = "http://localhost:8080/api/storages"
    
    static func fetchAll(token: String, search: String? = nil, page: Int = 0, size: Int? = nil) async throws -> PaginatedResponseDTO<StorageDTO> {
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

        return try JSONDecoder().decode(PaginatedResponseDTO<StorageDTO>.self, from: data)
    }

    static func fetchAllSummaries(token: String, search: String? = nil, page: Int = 0, size: Int? = nil) async throws -> PaginatedResponseDTO<StorageSummaryDTO> {
        var url = URL(string: "\(baseURL)/summary")!
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

        return try JSONDecoder().decode(PaginatedResponseDTO<StorageSummaryDTO>.self, from: data)
    }
    
    static func fetchById(token: String, id: Int) async throws -> StorageDTO {
        let url = URL(string: "\(baseURL)/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(StorageDTO.self, from: data)
    }
    
    static func create(token: String, name: String) async throws -> StorageDTO {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = CreateStorageRequestDTO(name: name)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(StorageDTO.self, from: data)
    }
    
    static func updateName(token: String, id: Int, name: String) async throws -> StorageDTO {
        let url = URL(string: "\(baseURL)/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = ChangeStorageNameRequestDTO(name: name)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(StorageDTO.self, from: data)
    }
    
    static func delete(token: String, id: Int) async throws {
        let url = URL(string: "\(baseURL)/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
    
    // MARK: - Storage Items
    
    static func fetchItems(token: String, storageId: Int) async throws -> [StorageItemDTO] {
        let url = URL(string: "\(baseURL)/\(storageId)/items")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode([StorageItemDTO].self, from: data)
    }
    
    static func addItem(token: String, storageId: Int, productId: Int, expiresAt: String) async throws -> StorageItemDTO {
        let url = URL(string: "\(baseURL)/\(storageId)/items")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = AddItemRequestDTO(productId: productId, expiresAt: expiresAt)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(StorageItemDTO.self, from: data)
    }
    
    static func updateItem(token: String, storageId: Int, itemId: Int, expiresAt: String?) async throws -> StorageItemDTO {
        let url = URL(string: "\(baseURL)/\(storageId)/items/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = EditItemRequestDTO(expiresAt: expiresAt)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(StorageItemDTO.self, from: data)
    }
    
    static func deleteItem(token: String, storageId: Int, itemId: Int) async throws {
        let url = URL(string: "\(baseURL)/\(storageId)/items/\(itemId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
    
    // MARK: - Storage Members
    
    static func fetchMembers(token: String, storageId: Int) async throws -> [StorageMemberDTO] {
        let url = URL(string: "\(baseURL)/\(storageId)/members")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode([StorageMemberDTO].self, from: data)
    }
    
    static func inviteMember(token: String, storageId: Int, email: String) async throws -> StorageMemberDTO {
        let url = URL(string: "\(baseURL)/\(storageId)/members")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = InviteMemberRequestDTO(email: email)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(StorageMemberDTO.self, from: data)
    }
    
    static func removeMember(token: String, storageId: Int, userId: Int) async throws {
        let url = URL(string: "\(baseURL)/\(storageId)/members/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Running Low Settings

    static func fetchRunningLowSettings(token: String, storageId: Int) async throws -> [RunningLowSettingDTO] {
        let url = URL(string: "\(baseURL)/\(storageId)/runninglowsettings")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        return try JSONDecoder().decode([RunningLowSettingDTO].self, from: data)
    }

    static func createRunningLowSetting(token: String, storageId: Int, productId: Int, threshold: Int) async throws -> RunningLowSettingDTO {
        let url = URL(string: "\(baseURL)/\(storageId)/runninglowsettings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let payload = CreateRunningLowSettingRequestDTO(productId: productId, runningLow: threshold)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        return try JSONDecoder().decode(RunningLowSettingDTO.self, from: data)
    }

    static func editRunningLowSetting(token: String, storageId: Int, settingId: Int, threshold: Int) async throws -> RunningLowSettingDTO {
        let url = URL(string: "\(baseURL)/\(storageId)/runninglowsettings/\(settingId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let payload = EditRunningLowSettingRequestDTO(runningLow: threshold)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        return try JSONDecoder().decode(RunningLowSettingDTO.self, from: data)
    }

    static func deleteRunningLowSetting(token: String, storageId: Int, settingId: Int) async throws {
        let url = URL(string: "\(baseURL)/\(storageId)/runninglowsettings/\(settingId)")!
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
