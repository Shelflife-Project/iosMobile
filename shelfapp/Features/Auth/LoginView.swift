import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel = LoginViewModel()

    private var color: Color {
        colorScheme == .dark ? Color(.indigo) : Color(.cyan)
    }
    
    var body: some View {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(color)

                    Text("Shelf Life")
                        .font(.system(size: 32, weight: .bold))

                    Text("Your personal inventory management system")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                Picker("Auth Mode", selection: selectedTab) {
                    Text("Login").tag(LoginViewModel.AuthTab.login)
                    Text("Sign Up").tag(LoginViewModel.AuthTab.signup)
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
    }

    private var selectedTab: Binding<LoginViewModel.AuthTab> {
        Binding(
            get: { viewModel.selectedTab },
            set: { viewModel.selectedTab = $0 }
        )
    }
}

#Preview {
    LoginView()
}
