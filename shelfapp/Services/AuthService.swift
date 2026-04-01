import Foundation
import Security

/// AuthService handles secure token persistence and auth operations.
/// API calls are delegated to APIHelper.
class AuthService {
    static let shared = AuthService()

    private let tokenKey = "shelflife_auth_token"

    // MARK: - Token Management

    func getStoredToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func saveToken(_ token: String) {
        clearToken()

        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary, nil)
        APIHelper.shared.setToken(token)
    }

    func clearToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]

        SecItemDelete(query as CFDictionary)
        APIHelper.shared.setToken(nil)
    }

    // MARK: - Auth Operations (delegates to APIHelper)

    func login(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }

        do {
            let (token, _) = try await APIHelper.shared.login(email: email, password: password)
            saveToken(token)
        } catch let error as APIError {
            if case .unauthorized = error {
                throw AuthError.invalidCredentials
            }
            throw error
        }
    }

    func signup(username: String, email: String, password: String, passwordRepeat: String) async throws {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }

        guard password == passwordRepeat else {
            throw AuthError.passwordMismatch
        }

        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }

        do {
            let (token, _) = try await APIHelper.shared.signup(username: username, email: email, password: password, passwordRepeat: passwordRepeat)
            saveToken(token)
        } catch let error as APIError {
            throw error
        }
    }

    func fetchCurrentUser() async throws -> User {
        guard getStoredToken() != nil else {
            throw AuthError.noToken
        }

        do {
            return try await APIHelper.shared.me()
        } catch let error as APIError {
            if case .unauthorized = error {
                clearToken()
                throw AuthError.tokenExpired
            }
            throw error
        }
    }

    func logout() {
        Task {
            await APIHelper.shared.logout()
        }
        clearToken()
    }
}

enum AuthError: LocalizedError {
    case invalidInput
    case invalidEmail
    case passwordMismatch
    case invalidCredentials
    case noToken
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please fill in all fields"
        case .invalidEmail:
            return "Invalid email address"
        case .passwordMismatch:
            return "Passwords do not match"
        case .invalidCredentials:
            return "Invalid email or password"
        case .noToken:
            return "Not authenticated"
        case .tokenExpired:
            return "Your session has expired, please log in again"
        }
    }
}
