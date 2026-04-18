import Foundation

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
