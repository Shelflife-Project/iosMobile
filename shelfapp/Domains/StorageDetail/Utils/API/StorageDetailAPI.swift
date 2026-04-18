import Foundation

protocol StorageDetailAPI {
    func fetchStorage(id: Int) async throws -> Storage
    func fetchStorageItems(storageId: Int) async throws -> [StorageItem]
    func fetchShoppingItems(storageId: Int) async throws -> [ShoppingListItem]
    func fetchRunningLowSettings(storageId: Int) async throws -> [RunningLowSetting]
    func fetchMembers(storageId: Int) async throws -> [StorageMemberInfo]
    func addStorageItem(storageId: Int, productId: Int, expiresAt: Date?) async throws -> StorageItem
    func removeMember(storageId: Int, userId: Int) async throws
    func inviteMember(storageId: Int, email: String) async throws -> StorageMemberInfo
    func deleteStorageItem(storageId: Int, itemId: Int) async throws
    func deleteShoppingItem(storageId: Int, itemId: Int) async throws
    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem
    func updateShoppingItemAmount(storageId: Int, itemId: Int, amountToBuy: Int) async throws -> ShoppingListItem
    func completeShoppingItem(storageId: Int, itemId: Int) async throws
    func createRunningLowSetting(storageId: Int, productId: Int, threshold: Int) async throws -> RunningLowSetting
    func updateRunningLowSetting(storageId: Int, settingId: Int, threshold: Int) async throws -> RunningLowSetting
    func deleteRunningLowSetting(storageId: Int, settingId: Int) async throws
}
