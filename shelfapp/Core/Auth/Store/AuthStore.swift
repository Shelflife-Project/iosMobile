import Foundation
import Observation

enum AuthError: Error {
    case invalidInput
    case invalidEmail
    case passwordMismatch
    case invalidCredentials
    case noToken
    case tokenExpired
    case signupError(SignupErrorDetails)
}

struct SignupErrorDetails: Equatable {
    let email: String
    let username: String
}

@MainActor
@Observable
final class AuthStore {
    // MARK: - State

    var sessionState: Loadable<User> = .idle
    var formState: Loadable<String> = .idle   // .loaded(token) on success

    var hasCheckedSession = false

    private let tokenStore: TokenStore
    private var _cachedToken: String?

    // MARK: - Derived

    var currentUser: User? { sessionState.value }
    var token: String? {
        get { _cachedToken }
        set {
            _cachedToken = newValue
            if let newValue {
                tokenStore.save(newValue)
            } else {
                tokenStore.delete()
            }
            sharedJWTToken = _cachedToken
        }
    }
    var isLoggedIn: Bool { token != nil && currentUser != nil }
    var isLoading: Bool { sessionState.isLoading || formState.isLoading }
    var errorMessage: String? {
        get {
            formState.error?.localizedDescription ?? sessionState.error?.localizedDescription
        }
        set {
            if let msg = newValue {
                formState = .failed(.serverMessage(msg))
            } else {
                if case .failed = formState { formState = .idle }
            }
        }
    }

    // MARK: - Persistence (user object stored in UserDefaults)

    var user: User? {
        get { currentUser }
        set {
            if let u = newValue {
                sessionState = .loaded(u)
                if let data = try? JSONEncoder().encode(u) {
                    UserDefaults.standard.set(data, forKey: "auth_user")
                }
            } else {
                sessionState = .idle
                UserDefaults.standard.removeObject(forKey: "auth_user")
            }
        }
    }

    // MARK: - Init

    init(tokenStore: TokenStore = KeychainTokenStore()) {
        self.tokenStore = tokenStore
        migrateTokenFromUserDefaultsIfNeeded()
        _cachedToken = tokenStore.token

        if let data = UserDefaults.standard.data(forKey: "auth_user"),
           let decoded = try? JSONDecoder().decode(User.self, from: data) {
            sessionState = .loaded(decoded)
        }
        if _cachedToken == nil {
            hasCheckedSession = true
        }
        sharedJWTToken = _cachedToken
    }

    // MARK: - Auth Operations

    func login(email: String, password: String) async throws -> String {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else { throw AuthError.invalidInput }
        guard email.contains("@") else { throw AuthError.invalidEmail }

        formState = .loading
        do {
            let response = try await AuthAPI.login(email: email, password: password)
            let userDto = try await AuthAPI.getMe(token: response.token)
            let loggedInUser = User(from: userDto)
            token = response.token
            user = loggedInUser
            hasCheckedSession = true
            formState = .loaded(response.token)
            return response.token
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            formState = .failed(.serverMessage(msg))
            throw error
        }
    }

    func signup(username: String, email: String, password: String, passwordRepeat: String) async throws -> String {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else { throw AuthError.invalidInput }
        guard email.contains("@") else { throw AuthError.invalidEmail }
        guard password == passwordRepeat else { throw AuthError.passwordMismatch }

        formState = .loading
        do {
            let response = try await AuthAPI.signup(email: email, username: username, password: password, passwordRepeat: passwordRepeat)
            let userDto = try await AuthAPI.getMe(token: response.token)
            let newUser = User(from: userDto)
            token = response.token
            user = newUser
            hasCheckedSession = true
            formState = .loaded(response.token)
            return response.token
        } catch {
            formState = .failed(.serverMessage(error.localizedDescription))
            throw error
        }
    }

    func fetchCurrentUser() async throws -> User {
        guard let token, !token.isEmpty else { throw AuthError.noToken }
        sessionState = .loading
        do {
            let userDto = try await AuthAPI.getMe(token: token)
            let fetchedUser = User(from: userDto)
            user = fetchedUser
            hasCheckedSession = true
            return fetchedUser
        } catch {
            hasCheckedSession = true
            sessionState = .failed(.serverMessage(error.localizedDescription))
            throw error
        }
    }

    func logout() {
        Task {
            if let t = token { try? await AuthAPI.logout(token: t) }
        }
        token = nil
        user = nil
        hasCheckedSession = true
        formState = .idle
    }

    func changePassword(oldPassword: String, newPassword: String, newPasswordRepeat: String) async throws {
        guard let token, !token.isEmpty else { throw AuthError.noToken }
        guard newPassword == newPasswordRepeat else { throw AuthError.passwordMismatch }

        formState = .loading
        do {
            try await AuthAPI.changePassword(token: token, oldPassword: oldPassword, newPassword: newPassword, newPasswordRepeat: newPasswordRepeat)
            formState = .idle
        } catch {
            formState = .failed(.serverMessage(error.localizedDescription))
            throw error
        }
    }

    // Compatibility helpers
    func getStoredToken() -> String? { token }
    func saveToken(_ t: String) { token = t }
    func clearToken() { token = nil }

    func me() async -> User? {
        try? await fetchCurrentUser()
    }

    // MARK: - Migration

    private func migrateTokenFromUserDefaultsIfNeeded() {
        let udKey = "jwt_token"
        guard tokenStore.token == nil,
              let legacy = UserDefaults.standard.string(forKey: udKey),
              !legacy.isEmpty else { return }
        tokenStore.save(legacy)
        UserDefaults.standard.removeObject(forKey: udKey)
    }
}
