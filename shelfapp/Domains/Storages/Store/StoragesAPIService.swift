import Foundation

// MARK: - User DTO (minimal, for storage owner)

struct UserDTO: Codable {
    let id: Int
    let username: String
    let admin: Bool

    func toDomain() -> User {
        User(username: username, admin: admin, serverId: id)
    }
}

// MARK: - Storage DTO

struct StorageDTO: Codable {
    let id: Int
    let name: String
    let owner: UserDTO?

    func toDomain() -> Storage {
        Storage(name: name, owner: owner?.toDomain(), serverId: id)
    }
}

// MARK: - Storage API Service

extension APIHelper {
    func fetchStoragesPage(search: String = "", size: Int = 0, page: Int = 0) async throws -> PaginatedResult<Storage> {
        guard let baseURL = normalizeURL("api/storages") else { throw APIError.invalidURL }

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
        if let pageResult = try? decoder.decode(PaginatedResponseDTO<StorageDTO>.self, from: data) {
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

        let fallbackItems = try decoder.decode([StorageDTO].self, from: data).map { $0.toDomain() }
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

    func fetchStorages() async throws -> [Storage] {
        try await fetchStoragesPage().items
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
}
