import SwiftUI

struct LoadingSkeleton: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = CornerRadius.sm

    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [Color.appSurface, Color.appSeparator.opacity(0.6), Color.appSurface],
                    startPoint: UnitPoint(x: phase - 0.3, y: 0.5),
                    endPoint: UnitPoint(x: phase + 0.3, y: 0.5)
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            LoadingSkeleton(height: 44, cornerRadius: CornerRadius.sm)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                LoadingSkeleton(height: 16).frame(maxWidth: 160)
                LoadingSkeleton(height: 12).frame(maxWidth: 100)
            }
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        ForEach(0..<4) { _ in SkeletonRow() }
    }
    .padding()
}
