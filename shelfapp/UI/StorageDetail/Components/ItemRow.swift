import SwiftUI

struct ItemRow: View {
    var item: StorageItem

    private var isExpired: Bool {
        guard let expiresAt = item.expiresAt else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return expiresAt < today
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.product?.name ?? "Unknown")
                    .font(AppFont.bodyEmphasized())
                if let category = item.product?.category, !category.isEmpty {
                    Text(category)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.appSecondaryLabel)
                }
            }

            Spacer()

            if let expires = item.expiresAt {
                ZStack(alignment: .topTrailing) {
                    Text(expires, format: .dateTime.month().day())
                        .font(AppFont.caption())
                        .foregroundStyle(isExpired ? Color.appDestructive : Color.appSecondaryLabel)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(isExpired ? Color.appDestructive.opacity(0.15) : Color.appPrimary.opacity(0.08))
                        )

                    if isExpired {
                        Circle()
                            .fill(Color.appDestructive)
                            .frame(width: 8, height: 8)
                            .offset(x: 3, y: -3)
                    }
                }
            }
        }
        .padding(.vertical, Spacing.sm)
        .listCardBackground(accent: .appPrimary)
    }
}
