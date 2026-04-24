import Foundation

enum ResourceURLBuilder {
    static func productIconURL(productId: Int) -> URL? {
        URL(string: "\(AppConfig.baseURL)/api/products/\(productId)/icon/small")
    }

    static func userProfilePictureURL(userId: Int) -> URL? {
        URL(string: "\(AppConfig.baseURL)/api/users/\(userId)/pfp/small")
    }
}
