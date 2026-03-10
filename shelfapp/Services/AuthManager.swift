import Foundation
import Observation

@Observable
class AuthManager {
    static let shared = AuthManager()

    var isAuthenticated = false
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?

    private init() {
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        if let token = AuthService.shared.getStoredToken() {
            APIService.shared.setToken(token)
            currentUser = AuthService.shared.getStoredUser()
            isAuthenticated = !token.isEmpty
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await AuthService.shared.login(email: email, password: password)
            // Explicitly ensure token is set in APIService
            if let token = AuthService.shared.getStoredToken() {
                APIService.shared.setToken(token)
            }
            currentUser = AuthService.shared.getStoredUser()
            isAuthenticated = true
            isLoading = false
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isAuthenticated = false
            isLoading = false
        }
    }

    func signup(username: String, email: String, password: String, passwordRepeat: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await AuthService.shared.signup(
                username: username,
                email: email,
                password: password,
                passwordRepeat: passwordRepeat
            )
            currentUser = AuthService.shared.getStoredUser()
            await login(email: email, password: password)
            isLoading = false
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            isLoading = false
        }
    }

    func logout() {
        AuthService.shared.logout()
        // Explicitly clear token from APIService
        APIService.shared.setToken(nil)
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }
}
