import SwiftUI

// MARK: - StatCard Animation Style

enum StatCardAnimation {
    case wiggle
    case drawOn
    case bounce
}

// MARK: - StatCard

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let accent: DomainAccent
    var animationStyle: StatCardAnimation = .bounce
    var isAnimating: Bool = false

    var body: some View {
        HStack(spacing: Spacing.base) {
            iconWell

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(AppFont.subheadline())
                    .foregroundStyle(Color.appSecondaryLabel)

                Text(value)
                    .font(AppFont.statValue())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: value)
            }

            Spacer(minLength: Spacing.sm)

            Image(systemName: "chevron.right")
                .font(AppFont.footnote())
                .fontWeight(.semibold)
                .foregroundStyle(Color.appSecondaryLabel.opacity(0.7))
        }
        .padding(Spacing.lg)
        .background(Color.appCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(accent.color.opacity(0.5), lineWidth: BorderWidth.regular)
        )
        .appShadow(radius: 16, y: 6, opacity: 0.10)
    }

    // MARK: - Icon well

    private var iconWell: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(accent.color.opacity(0.18))

            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(accent.color)
                .modifier(StatCardAnimationModifier(
                    style: animationStyle,
                    isAnimating: isAnimating
                ))
        }
        .frame(width: 56, height: 56)
    }
}

// MARK: - Animation Modifier

struct StatCardAnimationModifier: ViewModifier {
    let style: StatCardAnimation
    let isAnimating: Bool

    func body(content: Content) -> some View {
        switch style {
        case .wiggle:
            content.symbolEffect(.wiggle, isActive: isAnimating)
        case .drawOn:
            content.symbolEffect(.drawOn, isActive: isAnimating)
        case .bounce:
            content.symbolEffect(.bounce, options: .nonRepeating, value: isAnimating)
        }
    }
}

#Preview("Stat Cards") {
    VStack(spacing: Spacing.base) {
        StatCard(title: "Total Storages", value: "4", icon: "shippingbox.fill", accent: .storages, animationStyle: .bounce)
        StatCard(title: "Products", value: "128", icon: "carrot.fill", accent: .products, animationStyle: .drawOn)
        StatCard(title: "Shopping List", value: "12", icon: "cart.fill", accent: .shopping, animationStyle: .wiggle)
    }
    .padding()
    .background(
        LinearGradient(colors: [.appBgGradientTop, .appBgGradientBottom], startPoint: .top, endPoint: .bottom)
    )
}
