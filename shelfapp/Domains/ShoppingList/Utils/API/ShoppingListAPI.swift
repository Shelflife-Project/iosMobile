import Foundation

protocol ShoppingListAPI {
    func fetchShoppingItems(storageId: Int) async throws -> [ShoppingListItem]
    func fetchAggregatedShoppingItems() async throws -> [ShoppingListItem]
    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem
    func updateShoppingItemAmount(storageId: Int, itemId: Int, amountToBuy: Int) async throws -> ShoppingListItem
    func deleteShoppingItem(storageId: Int, itemId: Int) async throws
    func completeShoppingItem(storageId: Int, itemId: Int) async throws
    func addStorageItem(storageId: Int, productId: Int, expiresAt: Date?) async throws -> StorageItem
}
