import Foundation

enum AuthRequestBody {
    struct Login: Encodable {
        let email: String
        let password: String
    }

    struct Signup: Encodable {
        let username: String
        let email: String
        let password: String
        let passwordRepeat: String
    }

    struct ChangePassword: Encodable {
        let oldPassword: String
        let newPassword: String
        let newPasswordRepeat: String
    }
}

enum AuthRequestDTO {
    struct Login {
        let body: AuthRequestBody.Login
    }

    struct Signup {
        let body: AuthRequestBody.Signup
    }

    struct ChangePassword {
        let body: AuthRequestBody.ChangePassword
    }
}
