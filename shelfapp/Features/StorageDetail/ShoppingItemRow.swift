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
        HStack {
            Text(item.product?.name ?? "Unknown")
            Spacer()
            HStack(spacing: 8) {
                if let onDecrement {
                    Button(action: onDecrement) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(canDecrement ? .orange : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canDecrement)
                }

                Text("×\(item.amountToBuy)")
                    .fontWeight(.semibold)
                    .frame(minWidth: 32)

                if let onIncrement {
                    Button(action: onIncrement) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }

                if let onComplete {
                    Button(action: onComplete) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
