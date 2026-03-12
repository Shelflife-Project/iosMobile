import SwiftUI

struct ShoppingItemRow: View {
    var item: ShoppingListItem

    var body: some View {
        HStack {
            Text(item.product?.name ?? "Unknown")
            Spacer()
            Text("×\(item.amountToBuy)")
                .fontWeight(.semibold)
        }
    }
}
