import Foundation

protocol AuthAPI {
    func login(email: String, password: String) async throws -> (token: String, user: User)
    func signup(username: String, email: String, password: String, passwordRepeat: String) async throws -> (token: String, user: User)
    func me() async throws -> User
    func changePassword(oldPassword: String, newPassword: String, newPasswordRepeat: String) async throws
    func logout(token: String?) async throws
}

private struct AuthLoginDTO: Decodable {
    let token: String?
    let accessToken: String?
    let user: UserDTO?
}

private struct AuthSignupDTO: Decodable {
    let token: String?
    let accessToken: String?
    let user: UserDTO?
}

struct DefaultAuthAPI: AuthAPI {
    let http: HTTPClient

    func login(email: String, password: String) async throws -> (token: String, user: User) {
        let response: AuthLoginDTO = try await http.request(.login(LoginBody(email: email, password: password)))
        let token = response.accessToken ?? response.token ?? ""
        guard !token.isEmpty else { throw APIError.decodingError(NSError(domain: "AuthAPI", code: -1)) }
        return (token, response.user?.toDomain() ?? User(username: email))
    }

    func signup(username: String, email: String, password: String, passwordRepeat: String) async throws -> (token: String, user: User) {
        let response: AuthSignupDTO = try await http.request(.signup(SignupBody(username: username, email: email, password: password, passwordRepeat: passwordRepeat)))
        let token = response.accessToken ?? response.token ?? ""
        if !token.isEmpty, let user = response.user?.toDomain() {
            return (token, user)
        }

        return try await login(email: email, password: password)
    }

    func me() async throws -> User {
        let dto: UserDTO = try await http.request(.me)
        return dto.toDomain()
    }

    func changePassword(oldPassword: String, newPassword: String, newPasswordRepeat: String) async throws {
        let _: EmptyResponse = try await http.request(.changePassword(ChangePasswordBody(oldPassword: oldPassword, newPassword: newPassword, newPasswordRepeat: newPasswordRepeat)))
    }

    func logout(token: String?) async throws {
        guard token != nil else { return }
        let _: EmptyResponse = try await http.request(.logout)
    }
}
