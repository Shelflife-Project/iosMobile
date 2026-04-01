import SwiftUI
import Observation

@MainActor
@Observable
final class AuthPageViewModel {
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

struct AuthPage: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel = AuthPageViewModel()
    @State private var animateLogo = false

    private var color: Color {
        colorScheme == .dark ? Color(.indigo) : Color(.cyan)
    }
    
    var body: some View {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(color)
                        .symbolEffect(.bounce, options: .repeating, value: animateLogo)

                    Text("Shelf Life")
                        .font(.system(size: 32, weight: .bold))

                    Text("Your personal inventory management system")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                Picker("Auth Mode", selection: selectedTab) {
                    Text("Login").tag(AuthPageViewModel.AuthTab.login)
                    Text("Sign Up").tag(AuthPageViewModel.AuthTab.signup)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if viewModel.selectedTab == .login {
                    LoginFormView(email: $viewModel.email, password: $viewModel.password)
                } else {
                    SignupFormView(
                        username: $viewModel.username,
                        email: $viewModel.email,
                        password: $viewModel.password,
                        passwordRepeat: $viewModel.passwordRepeat
                    )
                }

                Spacer()
            }
            .padding()
            .appGradientBackground()
            .onAppear {
                animateLogo = true
            }
            .onDisappear {
                animateLogo = false
            }
    }

    private var selectedTab: Binding<AuthPageViewModel.AuthTab> {
        Binding(
            get: { viewModel.selectedTab },
            set: { viewModel.selectedTab = $0 }
        )
    }
}

#Preview {
    AuthPage()
}
