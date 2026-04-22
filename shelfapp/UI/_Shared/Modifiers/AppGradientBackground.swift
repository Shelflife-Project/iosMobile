import SwiftUI

/// App-wide background gradient sourced from semantic color assets.
/// Light: #f0fcff → #ffffff. Dark: #6c91a8 → #181a2a.
struct AppGradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        let top: Color = .appBgGradientTop
        let bottom: Color = .appBgGradientBottom
        let gradient = LinearGradient(
            gradient: Gradient(colors: [top, bottom]),
            startPoint: .top,
            endPoint: .bottom
        )
        return content
            .background(gradient.ignoresSafeArea())
    }
}

extension View {
    func appGradientBackground() -> some View {
        modifier(AppGradientBackground())
    }
}
