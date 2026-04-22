import Foundation

enum ProfileRequestBody {
    struct UpdateUser: Encodable {
        let username: String?
        let email: String?
    }
}

enum ProfileRequestDTO {
    struct UpdateUser {
        let id: Int
        let body: ProfileRequestBody.UpdateUser
    }

    struct UploadProfilePicture {
        let userId: Int
        let imageData: Data
    }
}
