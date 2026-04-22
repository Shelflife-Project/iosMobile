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
    @State private var viewModel = AuthPageViewModel()
    @State private var animateLogo = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .symbolEffect(.bounce, options: .repeating, value: animateLogo)

                Text("Shelf Life")
                    .font(AppFont.largeTitle())

                Text("Your personal inventory management system")
                    .font(AppFont.callout())
                    .foregroundStyle(Color.appSecondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Spacing.xxxl)
            .padding(.bottom, Spacing.lg)

            Picker("Auth Mode", selection: selectedTab) {
                Text("Login").tag(AuthPageViewModel.AuthTab.login)
                Text("Sign Up").tag(AuthPageViewModel.AuthTab.signup)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.base)

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
        .padding(.horizontal, Spacing.base)
        .appGradientBackground()
        .onAppear { animateLogo = true }
        .onDisappear { animateLogo = false }
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
