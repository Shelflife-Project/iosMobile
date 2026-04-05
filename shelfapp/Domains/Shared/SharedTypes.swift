import Foundation

// MARK: - Shared DTOs and Structures

struct PaginatedResponseDTO<T: Codable>: Codable {
    let data: [T]
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let pageSize: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

struct PaginatedResult<T> {
    let items: [T]
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let pageSize: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

/// Lightweight struct for member display (not a model)
struct StorageMemberInfo: Identifiable {
    let id: Int
    let userId: Int
    let username: String
    let accepted: Bool
}

/// Lightweight struct for pending invite display
struct PendingInviteInfo: Identifiable {
    let id: Int
    let storageName: String
    let storageId: Int
    let invitedBy: String
}

struct RunningLowNotification: Identifiable, Hashable {
    struct Item: Identifiable, Hashable {
        let id: Int
        let productName: String
        let quantity: Int
    }

    let storageId: Int
    let storageName: String
    let items: [Item]

    var id: String {
        "\(storageId)"
    }
}

enum ResourceURLBuilder {
    static func productIconURL(productId: Int) -> URL? {
        buildURL(path: "api/products/\(productId)/icon/small")
    }

    static func userProfilePictureURL(userId: Int) -> URL? {
        buildURL(path: "api/users/\(userId)/pfp/small")
    }

    private static func buildURL(path: String) -> URL? {
        guard var base = URL(string: AppConfig.baseURL) else { return nil }
        if !base.absoluteString.hasSuffix("/") {
            base = base.appendingPathComponent("")
        }
        return base.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}
