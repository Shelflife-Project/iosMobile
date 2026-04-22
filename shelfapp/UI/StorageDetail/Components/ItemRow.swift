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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.product?.name ?? "Unknown")
                    .font(.headline)
                if let category = item.product?.category, !category.isEmpty {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let expires = item.expiresAt {
                    ZStack(alignment: .topTrailing) {
                        Text(expires, format: .dateTime.month().day())
                            .font(.caption)
                            .foregroundStyle(isExpired ? .red : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(isExpired ? Color.red.opacity(0.15) : Color.clear)
                            )

                        if isExpired {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 3, y: -3)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
