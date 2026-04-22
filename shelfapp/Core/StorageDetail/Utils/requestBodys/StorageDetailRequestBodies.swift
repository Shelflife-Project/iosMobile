import Foundation

enum StorageDetailRequestBody {
    struct AddStorageItem: Encodable {
        let productId: Int
        let expiresAt: String?
    }

    struct AddShoppingItem: Encodable {
        let productId: Int
        let amountToBuy: Int
    }

    struct UpdateShoppingItem: Encodable {
        let amountToBuy: Int
    }

    struct InviteMember: Encodable {
        let email: String
    }

    struct CreateRunningLow: Encodable {
        let productId: Int
        let runningLow: Int
    }

    struct UpdateRunningLow: Encodable {
        let runningLow: Int
    }
}

enum StorageDetailRequestDTO {
    struct StorageId {
        let id: Int
    }

    struct StorageScope {
        let storageId: Int
    }

    struct StorageItemScope {
        let storageId: Int
        let itemId: Int
    }

    struct ShoppingItemScope {
        let storageId: Int
        let itemId: Int
    }

    struct MemberScope {
        let storageId: Int
        let userId: Int
    }

    struct InviteMember {
        let storageId: Int
        let body: StorageDetailRequestBody.InviteMember
    }

    struct AddStorageItem {
        let storageId: Int
        let body: StorageDetailRequestBody.AddStorageItem
    }

    struct AddShoppingItem {
        let storageId: Int
        let body: StorageDetailRequestBody.AddShoppingItem
    }

    struct UpdateShoppingItem {
        let storageId: Int
        let itemId: Int
        let body: StorageDetailRequestBody.UpdateShoppingItem
    }

    struct RunningLowScope {
        let storageId: Int
    }

    struct CreateRunningLow {
        let storageId: Int
        let body: StorageDetailRequestBody.CreateRunningLow
    }

    struct UpdateRunningLow {
        let storageId: Int
        let settingId: Int
        let body: StorageDetailRequestBody.UpdateRunningLow
    }

    struct DeleteRunningLow {
        let storageId: Int
        let settingId: Int
    }
}
