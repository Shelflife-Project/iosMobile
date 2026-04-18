import Foundation

protocol ProfileAPI {
    func updateUser(id: Int, username: String?, email: String?) async throws -> User
    func uploadUserProfilePicture(userId: Int, imageData: Data) async throws
}
