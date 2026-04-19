import Foundation

enum ShoppingListRequestBody {
    struct AddItem: Encodable {
        let productId: Int
        let amountToBuy: Int
    }

    struct UpdateItem: Encodable {
        let amountToBuy: Int
    }

    struct AddStorageItem: Encodable {
        let productId: Int
        let expiresAt: String?
    }
}

enum ShoppingListRequestDTO {
    struct StorageScope {
        let storageId: Int
    }

    struct ShoppingItemScope {
        let storageId: Int
        let itemId: Int
    }

    struct AddShoppingItem {
        let storageId: Int
        let body: ShoppingListRequestBody.AddItem
    }

    struct UpdateShoppingItem {
        let storageId: Int
        let itemId: Int
        let body: ShoppingListRequestBody.UpdateItem
    }

    struct AddStorageItem {
        let storageId: Int
        let body: ShoppingListRequestBody.AddStorageItem
    }
}
