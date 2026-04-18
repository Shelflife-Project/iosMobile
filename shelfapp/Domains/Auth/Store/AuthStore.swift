import Observation
import Foundation

@MainActor
@Observable
class AuthStore {
    private let api: AuthAPI
    private let authService: AuthService

    var user: User?
    var isLoggedIn = false
    var isLoading = false
    var errorMessage: String?
    var hasCheckedSession = false
    var token: String? {
        didSet {
            guard oldValue != token else { return }
            if let token {
                authService.saveToken(token)
            } else {
                authService.clearToken()
            }
        }
    }

    init(api: AuthAPI, authService: AuthService) {
        self.api = api
        self.authService = authService
        let storedToken = authService.getStoredToken()
        self.token = storedToken
        self.isLoggedIn = storedToken?.isEmpty == false
    }

    convenience init(api: AuthAPI) {
        self.init(api: api, authService: .shared)
    }

    convenience init() {
        self.init(api: DefaultAuthAPI(http: DefaultHTTPClient()), authService: .shared)
    }

    @discardableResult
    func me() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasCheckedSession = true
        }

        guard token != nil else {
            logout()
            return false
        }

        do {
            user = try await api.me()
            isLoggedIn = true
            hasCheckedSession = true
            return true
        } catch APIError.forbidden {
            logout()
            hasCheckedSession = true
            return false
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            logout()
            hasCheckedSession = true
            return false
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await api.login(email: email, password: password)
            token = response.token
            user = response.user
            isLoggedIn = true
            hasCheckedSession = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isLoggedIn = false
        }
    }

    func register(username: String, email: String, password: String, passwordRepeat: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await api.signup(
                username: username,
                email: email,
                password: password,
                passwordRepeat: passwordRepeat
            )
            token = response.token
            user = response.user
            isLoggedIn = true
            hasCheckedSession = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func signup(username: String, email: String, password: String, passwordRepeat: String) async {
        await register(username: username, email: email, password: password, passwordRepeat: passwordRepeat)
    }

    func logout() {
        Task { try? await api.logout(token: token) }
        token = nil
        isLoggedIn = false
        user = nil
    }
}
