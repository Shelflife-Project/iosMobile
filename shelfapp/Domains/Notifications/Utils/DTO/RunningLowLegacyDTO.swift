import Foundation

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
