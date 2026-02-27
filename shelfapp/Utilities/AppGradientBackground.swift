import SwiftUI

struct AppGradientBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(red: 0.15, green: 0.05, blue: 0.25), .black]
                        : [Color(red: 0.93, green: 0.88, blue: 0.97), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func appGradientBackground() -> some View {
        modifier(AppGradientBackground())
    }
}
