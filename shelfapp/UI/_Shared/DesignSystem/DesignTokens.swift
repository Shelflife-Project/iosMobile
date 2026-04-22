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
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 999
}

// MARK: - Typography

enum AppFont {
    static func largeTitle() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func title2() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func title3() -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func body() -> Font { .system(size: 17, weight: .regular, design: .default) }
    static func callout() -> Font { .system(size: 16, weight: .regular, design: .default) }
    static func subheadline() -> Font { .system(size: 15, weight: .regular, design: .default) }
    static func footnote() -> Font { .system(size: 13, weight: .regular, design: .default) }
    static func caption() -> Font { .system(size: 12, weight: .regular, design: .default) }
    static func caption2() -> Font { .system(size: 11, weight: .regular, design: .default) }
}

// MARK: - Colors (semantic, resolve at runtime)

extension Color {
    static var appPrimary: Color { Color("appPrimary") }
    static var appAccent: Color { Color("appAccent") }
    static var appSurface: Color { Color("appSurface") }
    static var appBackground: Color { Color("appBackground") }
    static var appDestructive: Color { Color("appDestructive") }
    static var appSecondaryLabel: Color { Color("appSecondaryLabel") }
    static var appSeparator: Color { Color("appSeparator") }
}

// MARK: - Shadow

struct AppShadow: ViewModifier {
    var radius: CGFloat = 8
    var y: CGFloat = 2

    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.08), radius: radius, x: 0, y: y)
    }
}

extension View {
    func appShadow(radius: CGFloat = 8, y: CGFloat = 2) -> some View {
        modifier(AppShadow(radius: radius, y: y))
    }
}
