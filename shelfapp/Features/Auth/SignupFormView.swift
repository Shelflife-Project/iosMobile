import SwiftUI

struct SignupFormView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AuthContext.self) private var authContext
    @Binding var username: String
    @Binding var email: String
    @Binding var password: String
    @Binding var passwordRepeat: String

    private var color: Color {
        colorScheme == .dark ? Color(.indigo) : Color(.cyan)
    }
    
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

            if let error = authContext.errorMessage {
                Spacer()
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
                Spacer()
            }
            Spacer()

            Button(action: signup) {
                if authContext.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundStyle(.white)
            .cornerRadius(8)
            .disabled(authContext.isLoading || username.isEmpty || email.isEmpty || password.isEmpty || passwordRepeat.isEmpty)
        }
    }

    private func signup() {
        Task {
            await authContext.signup(
                username: username,
                email: email,
                password: password,
                passwordRepeat: passwordRepeat
            )
        }
    }
}
