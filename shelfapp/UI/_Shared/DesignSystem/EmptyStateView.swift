import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var message: String? = nil
    var action: (label: String, handler: () -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: systemImage)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.appSecondaryLabel)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(AppFont.title3())
                    .multilineTextAlignment(.center)

                if let message {
                    Text(message)
                        .font(AppFont.subheadline())
                        .foregroundStyle(Color.appSecondaryLabel)
                        .multilineTextAlignment(.center)
                }
            }

            if let action {
                Button(action.label, action: action.handler)
                    .buttonStyle(.primary)
                    .padding(.horizontal, Spacing.xxxl)
            }
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Empty State") {
    EmptyStateView(
        systemImage: "tray",
        title: "Nothing here yet",
        message: "Add your first item to get started.",
        action: ("Add Item", {})
    )
    .preferredColorScheme(.light)
}

#Preview("Empty State — Dark") {
    EmptyStateView(
        systemImage: "tray",
        title: "Nothing here yet",
        message: "Add your first item to get started.",
        action: ("Add Item", {})
    )
    .preferredColorScheme(.dark)
}
