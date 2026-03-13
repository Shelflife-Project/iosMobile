import SwiftUI

struct LoginFormView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var email: String
    @Binding var password: String
    @State private var errorMessage: String?
    @State private var isLoading = false
    var authManager = AuthManager.shared

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

            if let error = errorMessage {
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
            .background(color)
            .foregroundStyle(.white)
            .cornerRadius(8)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .shadow(radius: 4, x: 3, y: 3)
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
