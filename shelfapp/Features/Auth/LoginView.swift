import SwiftUI

struct LoginView: View {
    @State private var selectedTab: AuthTab = .login
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var passwordRepeat = ""

    enum AuthTab {
        case login
        case signup
    }

    var body: some View {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text("Shelf Life")
                        .font(.system(size: 32, weight: .bold))

                    Text("Your personal inventory management system")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                Picker("Auth Mode", selection: $selectedTab) {
                    Text("Login").tag(AuthTab.login)
                    Text("Sign Up").tag(AuthTab.signup)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedTab == .login {
                    LoginFormView(email: $email, password: $password)
                } else {
                    SignupFormView(
                        username: $username,
                        email: $email,
                        password: $password,
                        passwordRepeat: $passwordRepeat
                    )
                }

                Spacer()
            }
            .padding()
            .appGradientBackground()
    }
}

#Preview {
    LoginView()
}
