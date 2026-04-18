import Foundation

// MARK: - User DTO (minimal, for storage owner)

struct UserDTO: Codable {
    let id: Int
    let username: String
    let admin: Bool

    func toDomain() -> User {
        User(username: username, admin: admin, serverId: id)
    }
}

// MARK: - Storage DTO

struct StorageDTO: Codable {
    let id: Int
    let name: String
    let owner: UserDTO?

    func toDomain() -> Storage {
        Storage(name: name, owner: owner?.toDomain(), serverId: id)
    }
}
