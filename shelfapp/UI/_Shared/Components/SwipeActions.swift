import SwiftUI

// Shared trailing swipe configuration so list rows behave consistently across pages.
extension View {
    func trailingSwipeActions<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: false) {
            content()
        }
    }
}

// Reusable swipe button used by pages and row components.
struct SwipeActionButton: View {
    var title: String
    var systemImage: String
    var tint: Color = .accentColor
    var role: ButtonRole? = nil
    var action: () -> Void

    var body: some View {
        Button(role: role) {
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(tint.opacity(0.35), lineWidth: 0.75)
                    )

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 2)
        }
        .tint(tint)
    }
}
