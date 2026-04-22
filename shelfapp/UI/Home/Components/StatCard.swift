import SwiftUI

// MARK: - StatCard Animation Style

enum StatCardAnimation {
    case wiggle
    case drawOn
}

// MARK: - StatCard

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var animationStyle: StatCardAnimation = .drawOn
    var isAnimating: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .cornerRadius(8)
                .modifier(StatCardAnimationModifier(
                    style: animationStyle,
                    isAnimating: isAnimating
                ))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 4, x: 3, y: 3)
    }
}

// MARK: - Animation Modifier

struct StatCardAnimationModifier: ViewModifier {
    let style: StatCardAnimation
    let isAnimating: Bool

    func body(content: Content) -> some View {
        switch style {
        case .wiggle:
            content
                .symbolEffect(.wiggle, isActive: isAnimating)
        case .drawOn:
            content
                .symbolEffect(.drawOn, isActive: isAnimating)
        }
    }
}
