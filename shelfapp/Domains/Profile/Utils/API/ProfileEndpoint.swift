import Foundation

enum ProfileEndpoint: HTTPEndpoint {
    case updateUser(ProfileRequestDTO.UpdateUser)
    case uploadUserProfilePicture(ProfileRequestDTO.UploadProfilePicture)

    private static let profileUploadBoundary = "ShelfLifeProfileUploadBoundary"

    private static func profileUploadBody(imageData: Data) -> Data {
        var body = Data()
        let boundary = profileUploadBoundary
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"pfp\"; filename=\"pfp.jpg\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(imageData)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        return body
    }

    var path: String {
        switch self {
        case .updateUser(let request): return "/api/users/\(request.id)"
        case .uploadUserProfilePicture(let request): return "/api/users/\(request.userId)/pfp"
        }
    }

    var method: String {
        switch self {
        case .updateUser:
            return "PATCH"
        case .uploadUserProfilePicture:
            return "POST"
        }
    }

    var body: AnyEncodable? {
        switch self {
        case .updateUser(let request):
            return AnyEncodable(request.body)
        default:
            return nil
        }
    }

    var rawBody: Data? {
        switch self {
        case .uploadUserProfilePicture(let request):
            return Self.profileUploadBody(imageData: request.imageData)
        default:
            return nil
        }
    }

    var contentType: String? {
        switch self {
        case .updateUser:
            return "application/json"
        case .uploadUserProfilePicture:
            return "multipart/form-data; boundary=\(Self.profileUploadBoundary)"
        }
    }
}
