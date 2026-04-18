import Foundation

struct UserDTO: Codable {
    let id: Int
    let username: String
    let admin: Bool

    func toDomain() -> User {
        User(username: username, admin: admin, serverId: id)
    }
}
