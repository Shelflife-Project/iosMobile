import Observation
import Foundation

@MainActor
@Observable
class ProfileStore {
    var currentUser: User?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    private let api: ProfileAPI

    init(api: ProfileAPI = DefaultProfileAPI()) {
        self.api = api
    }

    convenience init() {
        self.init(api: DefaultProfileAPI())
    }

    func sync(from authContext: AuthStore) {
        currentUser = authContext.user
        isAuthenticated = authContext.isLoggedIn
    }

    func refreshCurrentUser(authContext: AuthStore) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        _ = await authContext.me()
        errorMessage = authContext.errorMessage
        sync(from: authContext)
    }

    @discardableResult
    func updateAccount(userId: Int, username: String, profileImageData: Data?, authContext: AuthStore) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await api.updateUser(id: userId, username: username, email: nil)

            if let profileImageData {
                try await api.uploadUserProfilePicture(userId: userId, imageData: profileImageData)
            }

            _ = await authContext.me()
            sync(from: authContext)
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func logout(authContext: AuthStore) {
        authContext.logout()
        sync(from: authContext)
    }
}
