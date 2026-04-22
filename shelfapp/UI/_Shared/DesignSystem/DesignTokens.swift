import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Border

enum BorderWidth {
    static let hairline: CGFloat = 1
    static let regular: CGFloat = 1.5
    static let thick: CGFloat = 2.5
}

// MARK: - Typography — all rounded for a warm, friendly feel

enum AppFont {
    static func largeTitle() -> Font { .system(size: 36, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 30, weight: .bold, design: .rounded) }
    static func title2() -> Font { .system(size: 24, weight: .semibold, design: .rounded) }
    static func title3() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 18, weight: .semibold, design: .rounded) }
    static func body() -> Font { .system(size: 17, weight: .regular, design: .rounded) }
    static func bodyEmphasized() -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func callout() -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    static func subheadline() -> Font { .system(size: 15, weight: .regular, design: .rounded) }
    static func footnote() -> Font { .system(size: 13, weight: .regular, design: .rounded) }
    static func caption() -> Font { .system(size: 12, weight: .medium, design: .rounded) }
    static func caption2() -> Font { .system(size: 11, weight: .medium, design: .rounded) }

    /// Big numeric display used in home-screen stat cards.
    static func statValue() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
}

// MARK: - Colors
//
// Semantic colors live in Assets.xcassets (see appPrimary.colorset, etc.).
// Xcode auto-generates `Color.appPrimary`-style accessors from the asset
// catalog — no manual `extension Color` needed (and duplicating them causes
// "ambiguous use" compile errors).

// MARK: - Domain colors (for stat cards, icons, domain-tinted UI)

enum DomainAccent {
    case storages
    case products
    case shopping

    var color: Color {
        switch self {
        case .storages: return .appPrimary
        case .products: return .appAccentFresh
        case .shopping: return .appAccentWarm
        }
    }
}

// MARK: - Shadow

struct AppShadow: ViewModifier {
    var radius: CGFloat
    var y: CGFloat
    var opacity: Double

    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: y)
    }
}

extension View {
    /// Soft ambient shadow tuned for cards and sheets.
    func appShadow(radius: CGFloat = 12, y: CGFloat = 4, opacity: Double = 0.08) -> some View {
        modifier(AppShadow(radius: radius, y: y, opacity: opacity))
    }

    /// Lighter shadow for inline rows / buttons.
    func appShadowSubtle() -> some View {
        modifier(AppShadow(radius: 6, y: 2, opacity: 0.05))
    }
}

// MARK: - Soft bordered surface (building block for cards & chips)

struct SoftBorderedSurface: ViewModifier {
    var radius: CGFloat
    var fill: Color
    var strokeOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.appBorder.opacity(strokeOpacity), lineWidth: BorderWidth.hairline)
            )
    }
}

extension View {
    func softBordered(
        radius: CGFloat = CornerRadius.md,
        fill: Color = .appSurface,
        strokeOpacity: Double = 1.0
    ) -> some View {
        modifier(SoftBorderedSurface(radius: radius, fill: fill, strokeOpacity: strokeOpacity))
    }
}

// MARK: - Adaptive card surface
// Slightly off-white in light mode (#F2F2F7) so cards read clearly against the white gradient.
// Elevated dark surface in dark mode (#1C1C1E) for natural depth.

extension Color {
    static var appCardSurface: Color { Color(.secondarySystemBackground) }
}

// MARK: - List card row modifier
// Edge-to-edge appCardSurface background with 2 pt row gaps and standard horizontal content padding.
// No border, no radius — clean flat rows that float on the gradient.

extension View {
    func listCardBackground(accent: Color = .appPrimary) -> some View {
        self
            .padding(.horizontal, Spacing.base)
            .listRowBackground(Color.appCardSurface)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
    }
}
