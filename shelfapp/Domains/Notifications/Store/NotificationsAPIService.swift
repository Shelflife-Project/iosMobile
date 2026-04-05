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
