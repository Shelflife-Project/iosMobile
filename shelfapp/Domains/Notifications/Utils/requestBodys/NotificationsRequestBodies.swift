import Foundation

enum NotificationsRequestBody {
    struct AddShoppingItem: Encodable {
        let productId: Int
        let amountToBuy: Int
    }
}

enum NotificationsRequestDTO {
    struct InviteId {
        let inviteId: Int
    }

    struct StorageItemScope {
        let storageId: Int
        let itemId: Int
    }

    struct AddShoppingItem {
        let storageId: Int
        let body: NotificationsRequestBody.AddShoppingItem
    }
}
