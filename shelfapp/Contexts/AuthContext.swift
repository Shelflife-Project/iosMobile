import Observation
import Foundation

@MainActor
@Observable
class AuthContext {
    var isAuthenticated = false
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?

    private let authService: AuthService
    private let apiService: APIService

    init(authService: AuthService = .shared, apiService: APIService = .shared) {
        self.authService = authService
        self.apiService = apiService

        let storedToken = authService.getStoredToken()
        apiService.configure(baseURL: AppConfig.baseURL, token: storedToken)
        restoreSessionFromStorage()
    }

    func restoreSessionFromStorage() {
        if let token = authService.getStoredToken(), !token.isEmpty {
            apiService.setToken(token)
            currentUser = authService.getStoredUser()
            isAuthenticated = true
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }

    @discardableResult
    func refreshCurrentUser() async -> Bool {
        errorMessage = nil

        guard authService.getStoredToken() != nil else {
            logout()
            return false
        }

        do {
            let user = try await authService.fetchCurrentUser()
            currentUser = user
            isAuthenticated = true
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
            currentUser = authService.getStoredUser()
            isAuthenticated = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isAuthenticated = false
        }
    }

    func signup(username: String, email: String, password: String, passwordRepeat: String) async {
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

    func logout() {
        authService.logout()
        apiService.setToken(nil)
        isAuthenticated = false
        currentUser = nil
    }
}
