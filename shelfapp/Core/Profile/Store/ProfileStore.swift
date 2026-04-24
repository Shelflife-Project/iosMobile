import Foundation
import Observation

@MainActor
@Observable
final class ProfileStore {
    private let auth: AuthStore

    var isAuthenticated = false
    var profilePictureState: Loadable<Void> = .idle
    var passwordChangeState: Loadable<Void> = .idle

    var isLoading: Bool { profilePictureState.isLoading || passwordChangeState.isLoading }
    var errorMessage: String? {
        get { profilePictureState.error?.localizedDescription ?? passwordChangeState.error?.localizedDescription }
        set {
            if let msg = newValue {
                profilePictureState = .failed(.serverMessage(msg))
            } else {
                if case .failed = profilePictureState { profilePictureState = .idle }
                if case .failed = passwordChangeState { passwordChangeState = .idle }
            }
        }
    }

    var currentUser: User? { auth.user }

    init(auth: AuthStore) {
        self.auth = auth
    }

    func sync(from authContext: AuthStore) {
        isAuthenticated = authContext.isLoggedIn
    }

    func refreshCurrentUser() async {
        profilePictureState = .loading
        do {
            guard let token = auth.token else { throw APIError.unauthorized }
            guard let userId = auth.user?.serverId else { throw APIError.unauthorized }
            let userDTO = try await ProfileAPI.getUser(token: token, id: userId)
            let updated = userDTO.toDomain()
            auth.user = updated
            profilePictureState = .idle
        } catch {
            profilePictureState = .failed(.serverMessage(error.localizedDescription))
        }
    }

    @discardableResult
    func updateAccount(userId: Int, username: String, profileImageData: Data?) async -> Bool {
        profilePictureState = .loading
        do {
            guard let token = auth.token else { throw APIError.unauthorized }
            _ = try await ProfileAPI.updateUser(token: token, id: userId, email: nil, username: username, isAdmin: nil)
            if let profileImageData {
                try await ProfileAPI.uploadProfilePicture(token: token, userId: userId, imageData: profileImageData)
            }
            let userDTO = try await ProfileAPI.getUser(token: token, id: userId)
            let updated = userDTO.toDomain()
            auth.user = updated
            profilePictureState = .idle
            return true
        } catch {
            profilePictureState = .failed(.serverMessage(error.localizedDescription))
            return false
        }
    }

    func logout() {
        auth.logout()
        isAuthenticated = false
        profilePictureState = .idle
        passwordChangeState = .idle
    }
}

typealias ProfileService = ProfileStore
