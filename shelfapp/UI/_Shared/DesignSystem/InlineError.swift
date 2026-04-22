import SwiftUI

struct InlineError: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.appDestructive)
            Text(message)
                .font(AppFont.footnote())
                .foregroundStyle(Color.appDestructive)
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.appDestructive.opacity(0.1))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
