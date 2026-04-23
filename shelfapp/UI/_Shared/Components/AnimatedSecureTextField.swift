import SwiftUI

struct AnimatedSecureTextField: View {
    @Binding var text: String
    @State private var isSecure = true
    var titleKey: String

    var body: some View {
        ZStack(alignment: .trailing) {
            if isSecure {
                SecureField(titleKey, text: $text)
                    .textContentType(.password)
            } else {
                TextField(titleKey, text: $text)
                    .textInputAutocapitalization(.never)
            }

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .foregroundStyle(Color.appSecondaryLabel)
                    .padding(.trailing, Spacing.md)
            }
        }
        .font(AppFont.body())
        .padding(Spacing.md)
        .softBordered(radius: CornerRadius.sm, fill: .appCardSurface)
        .appShadowSubtle()
        .animation(.easeInOut(duration: 0.2), value: isSecure)
    }
}

#Preview {
    @Previewable @State var text = ""
    AnimatedSecureTextField(text: $text, titleKey: "Password")
        .padding()
        .appGradientBackground()
}
