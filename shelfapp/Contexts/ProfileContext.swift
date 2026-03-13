import Observation

@MainActor
@Observable
class ProfileContext {
    var currentUser: User?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    func sync(from authContext: AuthContext) {
        currentUser = authContext.currentUser
        isAuthenticated = authContext.isAuthenticated
    }

    func refreshCurrentUser(authContext: AuthContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        _ = await authContext.refreshCurrentUser()
        errorMessage = authContext.errorMessage
        sync(from: authContext)
    }

    func logout(authContext: AuthContext) {
        authContext.logout()
        sync(from: authContext)
    }
}
