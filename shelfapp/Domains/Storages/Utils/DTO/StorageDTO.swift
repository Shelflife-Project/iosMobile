import Foundation

struct StorageDTO: Codable {
    let id: Int
    let name: String
    let owner: UserDTO?

    func toDomain() -> Storage {
        Storage(name: name, owner: owner?.toDomain(), serverId: id)
    }
}
