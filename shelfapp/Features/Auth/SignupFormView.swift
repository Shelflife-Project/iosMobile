import SwiftUI

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
                    .shadow(radius: 4, x: 3, y: 3)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .shadow(radius: 4, x: 3, y: 3)

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .shadow(radius: 4, x: 3, y: 3)

                SecureField("Confirm Password", text: $passwordRepeat)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .shadow(radius: 4, x: 3, y: 3)
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
                .shadow(radius: 4, x: 3, y: 3)
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
