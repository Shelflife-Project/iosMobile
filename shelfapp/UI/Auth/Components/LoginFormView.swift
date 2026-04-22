import SwiftUI

struct LoginFormView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AuthService.self) private var authContext
    @Binding var email: String
    @Binding var password: String

    private var color: Color {
        colorScheme == .dark ? Color(.indigo) : Color(.cyan)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                TextField("Email...", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .shadow(radius: 4, x: 3, y: 3)

                AnimatedSecureTextField(text: $password, titleKey: "Password...")
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
            AuthActionButton(
                title: "Login",
                color: color,
                isLoading: authContext.isLoading,
                isDisabled: authContext.isLoading || email.isEmpty || password.isEmpty,
                action: login
            )
        }
    }

    private func login() {
        Task {
            _ = try? await authContext.login(email: email, password: password)
        }
    }
}
