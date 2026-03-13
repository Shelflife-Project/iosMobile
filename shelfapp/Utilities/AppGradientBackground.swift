import SwiftUI

struct AppGradientBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        let topColor: Color = colorScheme == .dark
        ? Color(.systemIndigo).opacity(0.30)
        : Color(.systemCyan).opacity(0.3)

        content
            .background(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: topColor, location: 0.0),
                        .init(color: topColor, location: 0.65),
                        .init(color: Color(.systemBackground), location: 2.2)
                    ]),
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
