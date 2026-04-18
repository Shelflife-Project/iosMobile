import Foundation

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
