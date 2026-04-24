import SwiftUI

struct LoginFormView: View {
    @Environment(AuthService.self) private var authContext
    @Binding var email: String
    @Binding var password: String

    var body: some View {
        VStack(spacing: Spacing.base) {
            VStack(spacing: Spacing.md) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .font(AppFont.body())
                    .padding(Spacing.md)
                    .softBordered(radius: CornerRadius.sm, fill: .appCardSurface)
                    .appShadowSubtle()

                AnimatedSecureTextField(text: $password, titleKey: "Password")
            }

            if let error = authContext.errorMessage {
                InlineError(message: error)
            }

            Spacer()

            Button {
                login()
            } label: {
                Group {
                    if authContext.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Login")
                    }
                }
            }
            .buttonStyle(.primary)
            .disabled(authContext.isLoading || email.isEmpty || password.isEmpty)
        }
    }

    private func login() {
        Task {
            _ = try? await authContext.login(email: email, password: password)
        }
    }
}
