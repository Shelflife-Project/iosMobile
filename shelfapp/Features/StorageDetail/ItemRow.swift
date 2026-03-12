import SwiftUI

struct ItemRow: View {
    var item: StorageItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product?.name ?? "Unknown")
                    .fontWeight(.semibold)
                if let category = item.product?.category, !category.isEmpty {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let expires = item.expiresAt {
                    Text(expires, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
