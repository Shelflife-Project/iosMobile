import SwiftUI

struct SignupFormView: View {
    @Environment(AuthService.self) private var authContext
    @Binding var username: String
    @Binding var email: String
    @Binding var password: String
    @Binding var passwordRepeat: String

    var body: some View {
        VStack(spacing: Spacing.base) {
            VStack(spacing: Spacing.md) {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .font(AppFont.body())
                    .padding(Spacing.md)
                    .softBordered(radius: CornerRadius.sm, fill: .appSurface)
                    .appShadowSubtle()

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .font(AppFont.body())
                    .padding(Spacing.md)
                    .softBordered(radius: CornerRadius.sm, fill: .appSurface)
                    .appShadowSubtle()

                AnimatedSecureTextField(text: $password, titleKey: "Password")
                AnimatedSecureTextField(text: $passwordRepeat, titleKey: "Confirm Password")
            }

            if let error = authContext.errorMessage {
                InlineError(message: error)
            }

            Spacer()

            Button {
                signup()
            } label: {
                Group {
                    if authContext.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign Up")
                    }
                }
            }
            .buttonStyle(.primary)
            .disabled(authContext.isLoading || username.isEmpty || email.isEmpty || password.isEmpty || passwordRepeat.isEmpty)
        }
    }

    private func signup() {
        Task {
            _ = try? await authContext.signup(
                username: username,
                email: email,
                password: password,
                passwordRepeat: passwordRepeat
            )
        }
    }
}
