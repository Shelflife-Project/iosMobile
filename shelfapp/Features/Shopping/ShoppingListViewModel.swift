import Observation

@MainActor
@Observable
final class ShoppingListViewModel {
    let emptyTitle = "Shopping List"
    let emptySubtitle = "No items to purchase"

    func itemTitle(for item: ShoppingListItem) -> String {
        item.product?.name ?? "Unknown product"
    }

    func itemAmountText(for item: ShoppingListItem) -> String {
        "Amount: \(item.amountToBuy)"
    }

    func itemStorageName(for item: ShoppingListItem) -> String? {
        item.storage?.name
    }
}
