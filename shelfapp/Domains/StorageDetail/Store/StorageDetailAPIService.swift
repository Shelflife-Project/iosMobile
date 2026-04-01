import Foundation

// MARK: - Running Low Setting DTO

struct RunningLowSettingDTO: Codable {
    let id: Int
    let product: ProductDTO?
    let threshold: Int

    func toDomain() -> RunningLowSetting {
        return RunningLowSetting(productId: product?.id ?? 0, threshold: threshold, serverId: id)
    }
}

// MARK: - Storage Item DTO

struct StorageItemDTO: Codable {
    let id: Int
    let storage: StorageDTO?
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

        return StorageItem(storage: storage?.toDomain(), product: product?.toDomain(), expiresAt: expiresAtDate, createdAt: createdAtDate, serverId: id)
    }
}

// MARK: - Storage Member DTO

struct StorageMemberDTO: Codable {
    struct UserInfo: Codable {
        let id: Int
        let username: String
    }

    let id: Int
    let storage: StorageDTO?
    let user: UserInfo
    let accepted: Bool
}

// MARK: - Storage Detail API Service

extension APIHelper {
    // MARK: - Storage Items
    
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

    // MARK: - Members

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

    // MARK: - Invites

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

    // MARK: - Running Low Settings

    func fetchRunningLowSettings(storageId: Int) async throws -> [RunningLowSetting] {
        guard let url = normalizeURL("api/storages/\(storageId)/runninglow") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode([RunningLowSettingDTO].self, from: data).map { $0.toDomain() }
    }

    func createRunningLowSetting(storageId: Int, productId: Int, threshold: Int) async throws -> RunningLowSetting {
        guard let url = normalizeURL("api/storages/\(storageId)/runninglow") else { throw APIError.invalidURL }

        let payload: [String: Any] = ["productId": productId, "threshold": threshold]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(RunningLowSettingDTO.self, from: data)
        return dto.toDomain()
    }

    func updateRunningLowSetting(storageId: Int, settingId: Int, threshold: Int) async throws -> RunningLowSetting {
        guard let url = normalizeURL("api/storages/\(storageId)/runninglow/\(settingId)") else { throw APIError.invalidURL }

        let payload: [String: Any] = ["threshold": threshold]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(RunningLowSettingDTO.self, from: data)
        return dto.toDomain()
    }

    func deleteRunningLowSetting(storageId: Int, settingId: Int) async throws {
        guard let url = normalizeURL("api/storages/\(storageId)/runninglow/\(settingId)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = buildHeaders()

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
}
