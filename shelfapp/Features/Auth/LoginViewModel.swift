import Observation

@MainActor
@Observable
final class LoginViewModel {
    enum AuthTab {
        case login
        case signup
    }

    var selectedTab: AuthTab = .login
    var email = ""
    var password = ""
    var username = ""
    var passwordRepeat = ""
}
