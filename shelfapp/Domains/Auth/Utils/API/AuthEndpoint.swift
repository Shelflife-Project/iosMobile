import Foundation

enum AuthEndpoint: HTTPEndpoint {
    case login(AuthRequestDTO.Login)
    case signup(AuthRequestDTO.Signup)
    case changePassword(AuthRequestDTO.ChangePassword)
    case me
    case logout

    var path: String {
        switch self {
        case .login: return "/api/auth/login"
        case .signup: return "/api/auth/signup"
        case .changePassword: return "/api/auth/password/change"
        case .me: return "/api/auth/me"
        case .logout: return "/api/auth/logout"
        }
    }

    var method: String {
        switch self {
        case .login, .signup, .changePassword, .logout:
            return "POST"
        case .me:
            return "GET"
        }
    }

    var body: AnyEncodable? {
        switch self {
        case .login(let request): return AnyEncodable(request.body)
        case .signup(let request): return AnyEncodable(request.body)
        case .changePassword(let request): return AnyEncodable(request.body)
        default: return nil
        }
    }

    var contentType: String? {
        switch self {
        case .login, .signup, .changePassword:
            return "application/json"
        default:
            return nil
        }
    }
}
