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
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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
        }
    }
}

struct LoginFormView: View {
    @Binding var email: String
    @Binding var password: String
    @State private var errorMessage: String?
    @State private var isLoading = false
    var authManager = AuthManager.shared

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            Button(action: login) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Login")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(8)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
        }
    }

    private func login() {
        isLoading = true
        errorMessage = nil

        Task {
            await authManager.login(email: email, password: password)
            isLoading = false

            if let error = authManager.errorMessage {
                errorMessage = error
            }
        }
    }
}

struct SignupFormView: View {
    @Binding var username: String
    @Binding var email: String
    @Binding var password: String
    @Binding var passwordRepeat: String
    @State private var errorMessage: String?
    @State private var isLoading = false
    var authManager = AuthManager.shared

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Confirm Password", text: $passwordRepeat)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            Button(action: signup) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(8)
            .disabled(isLoading || username.isEmpty || email.isEmpty || password.isEmpty || passwordRepeat.isEmpty)
        }
    }

    private func signup() {
        isLoading = true
        errorMessage = nil

        Task {
            await authManager.signup(
                username: username,
                email: email,
                password: password,
                passwordRepeat: passwordRepeat
            )
            isLoading = false

            if let error = authManager.errorMessage {
                errorMessage = error
            }
        }
    }
}

#Preview {
    LoginView()
}
