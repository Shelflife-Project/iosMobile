import Foundation

protocol ProfileAPI {
    func updateUser(id: Int, username: String?, email: String?) async throws -> User
    func uploadUserProfilePicture(userId: Int, imageData: Data) async throws
}

struct DefaultProfileAPI: ProfileAPI {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    init() {
        self.init(http: DefaultHTTPClient())
    }

    func updateUser(id: Int, username: String?, email: String?) async throws -> User {
        let dto: UserAuthDTO = try await http.request(.updateUser(id: id, body: UserUpdateBody(username: username, email: email)))
        return dto.toDomain()
    }

    func uploadUserProfilePicture(userId: Int, imageData: Data) async throws {
        let _: EmptyResponse = try await http.request(.uploadUserProfilePicture(userId: userId, imageData: imageData))
    }
}
