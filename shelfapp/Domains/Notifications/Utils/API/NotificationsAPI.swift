import Foundation

protocol NotificationsAPI {
    func fetchPendingInvites() async throws -> [PendingInviteInfo]
    func fetchAggregatedRunningLowNotifications() async throws -> [RunningLowNotification]
    func fetchAggregatedAboutToExpireItems() async throws -> [StorageItem]
    func acceptInvite(inviteId: Int) async throws
    func declineInvite(inviteId: Int) async throws
    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem
    func deleteStorageItem(storageId: Int, itemId: Int) async throws
}
