import SwiftUI

// MARK: - Primary Button

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(isDestructive ? Color.appDestructive : Color.appPrimary)
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .appShadowSubtle()
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    Haptics.impact(isDestructive ? .rigid : .medium)
                }
            }
    }
}

// MARK: - Secondary Button

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline())
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .stroke(Color.appPrimary, lineWidth: BorderWidth.regular)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Haptics.impact(.light) }
            }
    }
}

// MARK: - Soft Button (low-emphasis, tinted fill)

struct SoftButtonStyle: ButtonStyle {
    var tint: Color = .appPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.bodyEmphasized())
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm + 2)
            .padding(.horizontal, Spacing.base)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.22 : 0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Haptics.impact(.light) }
            }
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var destructive: PrimaryButtonStyle { PrimaryButtonStyle(isDestructive: true) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == SoftButtonStyle {
    static var soft: SoftButtonStyle { SoftButtonStyle() }
    static func soft(tint: Color) -> SoftButtonStyle { SoftButtonStyle(tint: tint) }
}
