import Observation
import Foundation

@MainActor
@Observable
class ProfileContext {
    var currentUser: User?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    convenience init() {
        self.init(apiService: .shared)
    }

    func sync(from authContext: AuthContext) {
        currentUser = authContext.user
        isAuthenticated = authContext.isLoggedIn
    }

    func refreshCurrentUser(authContext: AuthContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        _ = await authContext.me()
        errorMessage = authContext.errorMessage
        sync(from: authContext)
    }

    @discardableResult
    func updateAccount(userId: Int, username: String, profileImageData: Data?, authContext: AuthContext) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await apiService.updateUser(id: userId, username: username)

            if let profileImageData {
                try await apiService.uploadUserPfp(userId: userId, imageData: profileImageData)
            }

            _ = await authContext.me()
            sync(from: authContext)
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func logout(authContext: AuthContext) {
        authContext.logout()
        sync(from: authContext)
    }
}
