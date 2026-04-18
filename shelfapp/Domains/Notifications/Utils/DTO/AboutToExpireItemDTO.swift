import Foundation

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
