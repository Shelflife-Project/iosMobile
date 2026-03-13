import Observation
import Foundation

@MainActor
@Observable
class AuthContext {
    var user: User?
    var isLoggedIn = false
    var isLoading = false
    var errorMessage: String?
    var hasCheckedSession = false

    var token: String? {
        authService.getStoredToken()
    }

    private let authService: AuthService
    private let apiService: APIService

    init(authService: AuthService = .shared, apiService: APIService = .shared) {
        self.authService = authService
        self.apiService = apiService

        let storedToken = authService.getStoredToken()
        apiService.configure(baseURL: AppConfig.baseURL, token: storedToken)
        isLoggedIn = storedToken?.isEmpty == false
    }

    @discardableResult
    func me() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasCheckedSession = true
        }

        guard authService.getStoredToken() != nil else {
            logout()
            return false
        }

        do {
            user = try await authService.fetchCurrentUser()
            isLoggedIn = true
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            logout()
            return false
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.login(email: email, password: password)
            if let token = authService.getStoredToken() {
                apiService.setToken(token)
            }
            _ = await me()
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
            try await authService.signup(
                username: username,
                email: email,
                password: password,
                passwordRepeat: passwordRepeat
            )
            await login(email: email, password: password)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func signup(username: String, email: String, password: String, passwordRepeat: String) async {
        await register(username: username, email: email, password: password, passwordRepeat: passwordRepeat)
    }

    func logout() {
        authService.logout()
        apiService.setToken(nil)
        isLoggedIn = false
        user = nil
    }
}
