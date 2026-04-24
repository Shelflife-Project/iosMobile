import SwiftUI

// MARK: - Variants

enum AppCardStyle {
    /// Standard card: surface fill, hairline border, soft shadow.
    case standard
    /// Prominent card used on the Home screen — bigger radius, stronger shadow.
    case prominent
    /// Flat card (no shadow) for list rows or nested contexts.
    case flat
}

// MARK: - AppCard

struct AppCard<Content: View>: View {
    var style: AppCardStyle = .standard
    var padding: CGFloat? = nil
    let content: Content

    init(
        style: AppCardStyle = .standard,
        padding: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(resolvedPadding)
            .softBordered(radius: radius, fill: .appCardSurface)
            .modifier(ShadowForStyle(style: style))
    }

    private var radius: CGFloat {
        switch style {
        case .standard: return CornerRadius.md
        case .prominent: return CornerRadius.lg
        case .flat: return CornerRadius.md
        }
    }

    private var resolvedPadding: CGFloat {
        if let padding { return padding }
        switch style {
        case .standard: return Spacing.base
        case .prominent: return Spacing.lg
        case .flat: return Spacing.md
        }
    }
}

// MARK: - Shadow per style

private struct ShadowForStyle: ViewModifier {
    let style: AppCardStyle

    func body(content: Content) -> some View {
        switch style {
        case .standard:
            content.appShadow(radius: 10, y: 3, opacity: 0.06)
        case .prominent:
            content.appShadow(radius: 16, y: 6, opacity: 0.10)
        case .flat:
            content
        }
    }
}

// MARK: - Convenience

extension View {
    func appCard(style: AppCardStyle = .standard, padding: CGFloat? = nil) -> some View {
        AppCard(style: style, padding: padding) { self }
    }
}
