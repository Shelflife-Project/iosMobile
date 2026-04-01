import Foundation

// MARK: - Running Low Notification DTO

struct RunningLowNotificationDTO: Codable {
    let storageId: Int
    let storageName: String
    let items: [RunningLowItemDTO]

    struct RunningLowItemDTO: Codable {
        let id: Int
        let productName: String
        let quantity: Int
    }
}

// MARK: - Running Low Legacy DTO (current backend shape)

struct RunningLowLegacyDTO: Codable {
    struct StorageRefDTO: Codable {
        let id: Int
        let name: String
    }

    struct ProductRefDTO: Codable {
        let id: Int
        let name: String
    }

    let storage: StorageRefDTO
    let product: ProductRefDTO
    let runningLowAt: Int?
    let amount: Int
}

// MARK: - About To Expire Item DTO

struct AboutToExpireItemDTO: Codable {
    let id: Int
    let storage: StorageDTO?
    let product: ProductDTO?
    let expiresAt: String?
    let createdAt: String

    func toDomain() -> StorageItem {
        var expiresAtDate: Date? = nil
        if let expiresAt = expiresAt {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            expiresAtDate = dateFormatter.date(from: expiresAt)
            if expiresAtDate == nil {
                expiresAtDate = ISO8601DateFormatter().date(from: expiresAt)
            }
        }

        var createdAtDate: Date
        let isoFormatter = ISO8601DateFormatter()
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

// MARK: - Notifications API Service

extension APIHelper {
    // MARK: - Running Low Notifications

    func fetchAggregatedRunningLowNotifications() async throws -> [RunningLowNotification] {
        guard let url = normalizeURL("api/runninglow") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()

        if let groupedDTOs = try? decoder.decode([RunningLowNotificationDTO].self, from: data) {
            return groupedDTOs.map {
                RunningLowNotification(
                    storageId: $0.storageId,
                    storageName: $0.storageName,
                    items: $0.items.map { RunningLowNotification.Item(id: $0.id, productName: $0.productName, quantity: $0.quantity) }
                )
            }
        }

        if let legacyDTOs = try? decoder.decode([RunningLowLegacyDTO].self, from: data) {
            let grouped = Dictionary(grouping: legacyDTOs, by: { $0.storage.id })

            return grouped.compactMap { storageId, items in
                guard let first = items.first else { return nil }

                return RunningLowNotification(
                    storageId: storageId,
                    storageName: first.storage.name,
                    items: items.map {
                        RunningLowNotification.Item(
                            id: $0.product.id,
                            productName: $0.product.name,
                            quantity: $0.amount
                        )
                    }
                )
            }
            .sorted { $0.storageName.localizedCaseInsensitiveCompare($1.storageName) == .orderedAscending }
        }

        throw APIError.decodingError(NSError(domain: "NotificationsAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported running-low response payload"]))
    }

    // MARK: - About To Expire Items

    func fetchAggregatedAboutToExpireItems() async throws -> [StorageItem] {
        // Current backend endpoint is /api/abouttoexpire, keep legacy fallback.
        func requestData(for path: String) async throws -> Data {
            guard let url = normalizeURL(path) else { throw APIError.invalidURL }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = buildHeaders()

            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response)
            return data
        }

        let data: Data
        do {
            data = try await requestData(for: "api/abouttoexpire")
        } catch APIError.notFound {
            data = try await requestData(for: "api/storages/items/expiring")
        }

        let decoder = JSONDecoder()
        return try decoder.decode([AboutToExpireItemDTO].self, from: data).map { $0.toDomain() }
    }

    // MARK: - Invite Management

    func fetchStorageInvites() async throws -> [PendingInviteInfo] {
        // This is already in StorageDetailAPIService.fetchPendingInvites()
        // But we can expose it here as well for notifications context
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
}
