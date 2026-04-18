import Foundation

// MARK: - Product DTO

struct ProductDTO: Codable {
    let id: Int
    let ownerId: Int?
    let name: String
    let category: String
    let expirationDaysDelta: Int
    let barcode: String?

    func toDomain() -> Product {
        Product(name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode, ownerId: ownerId, serverId: id)
    }
}
