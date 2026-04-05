import Foundation

// MARK: - Shopping List Item DTO

struct ShoppingListItemDTO: Codable {
    let id: Int
    let storage: StorageDTO?
    let product: ProductDTO?
    let amountToBuy: Int

    func toDomain() -> ShoppingListItem {
        ShoppingListItem(storage: storage?.toDomain(), product: product?.toDomain(), amountToBuy: amountToBuy, serverId: id)
    }
}
