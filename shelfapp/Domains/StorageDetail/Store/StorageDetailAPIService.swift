import Foundation

// MARK: - Running Low Setting DTO

struct RunningLowSettingDTO: Decodable {
    let id: Int
    let product: ProductDTO?
    let threshold: Int

    enum CodingKeys: String, CodingKey {
        case id
        case product
        case threshold
        case runningLow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        product = try container.decodeIfPresent(ProductDTO.self, forKey: .product)
        threshold = try container.decodeIfPresent(Int.self, forKey: .threshold)
            ?? container.decode(Int.self, forKey: .runningLow)
    }

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
