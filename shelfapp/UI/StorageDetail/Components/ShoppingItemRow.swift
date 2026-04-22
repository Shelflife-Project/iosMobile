import SwiftUI

struct ShoppingItemRow: View {
    var item: ShoppingListItem
    var onIncrement: (() -> Void)? = nil
    var onDecrement: (() -> Void)? = nil
    var onComplete: (() -> Void)? = nil

    private var canDecrement: Bool {
        item.amountToBuy > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(item.product?.name ?? "Unknown")
                    .font(.headline)
                Spacer()
                Text("×\(item.amountToBuy)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                if let onDecrement {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(canDecrement ? .orange : .gray)
                    .disabled(!canDecrement)
                }

                if let onIncrement {
                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

                Spacer()

                if let onComplete {
                    Button(action: onComplete) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Done")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.7))
        )
    }
}
