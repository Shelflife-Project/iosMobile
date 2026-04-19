import Foundation

struct DefaultProfileAPI: ProfileAPI {
    private let http: ProfileHTTPClient

    init(http: ProfileHTTPClient) {
        self.http = http
    }

    init() {
        self.init(http: DefaultProfileHTTPClient())
    }

    func updateUser(id: Int, username: String?, email: String?) async throws -> User {
        let dto: UserAuthDTO = try await http.request(.updateUser(.init(id: id, body: ProfileRequestBody.UpdateUser(username: username, email: email))))
        return dto.toDomain()
    }

    func uploadUserProfilePicture(userId: Int, imageData: Data) async throws {
        let _: EmptyResponse = try await http.request(.uploadUserProfilePicture(.init(userId: userId, imageData: imageData)))
    }
}
