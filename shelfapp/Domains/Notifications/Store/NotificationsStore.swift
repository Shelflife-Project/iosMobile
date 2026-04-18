import Foundation
import Observation

@MainActor
@Observable
class NotificationsStore {
    var invites: [PendingInviteInfo] = []
    var runningLowItems: [RunningLowNotification] = []
    var aboutToExpireItems: [StorageItem] = []
    var isLoading = false
    var errorMessage: String?

    private let api: NotificationsAPI

    init(api: NotificationsAPI = DefaultNotificationsAPI()) {
        self.api = api
    }

    func fetchInvites() async {
        do {
            invites = try await api.fetchPendingInvites()
        } catch {
            errorMessage = "Failed to fetch invites: \(error.localizedDescription)"
        }
    }

    func fetchAll() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let invitesFetch = api.fetchPendingInvites()
            async let runningLowFetch = api.fetchAggregatedRunningLowNotifications()
            async let aboutToExpireFetch = api.fetchAggregatedAboutToExpireItems()

            invites = try await invitesFetch
            runningLowItems = try await runningLowFetch
            aboutToExpireItems = try await aboutToExpireFetch
        } catch {
            errorMessage = "Failed to fetch notifications: \(error.localizedDescription)"
        }
    }

    func refreshInvites() async {
        await fetchInvites()
    }

    func refreshAll() async {
        await fetchAll()
    }

    func acceptInvite(_ invite: PendingInviteInfo, storageContext: StorageStore) async {
        errorMessage = nil

        do {
            try await api.acceptInvite(inviteId: invite.id)
            invites.removeAll { $0.id == invite.id }
            await storageContext.fetch()
        } catch {
            errorMessage = "Failed to accept invite: \(error.localizedDescription)"
        }
    }

    func declineInvite(_ invite: PendingInviteInfo) async {
        errorMessage = nil

        do {
            try await api.declineInvite(inviteId: invite.id)
            invites.removeAll { $0.id == invite.id }
        } catch {
            errorMessage = "Failed to decline invite: \(error.localizedDescription)"
        }
    }

    func addRunningLowItemToShoppingList(storageId: Int, productId: Int, shoppingListContext: ShoppingListStore) async {
        errorMessage = nil

        do {
            _ = try await api.addShoppingItem(storageId: storageId, productId: productId, amountToBuy: 1)
            await shoppingListContext.fetchAggregated()
        } catch {
            errorMessage = "Failed to add running low item to shopping list: \(error.localizedDescription)"
        }
    }

    func deleteExpiredItem(_ item: StorageItem) async {
        errorMessage = nil

        do {
            guard let storageId = item.storage?.serverId, let itemId = item.serverId else {
                throw APIError.invalidURL
            }

            try await api.deleteStorageItem(storageId: storageId, itemId: itemId)
            aboutToExpireItems = try await api.fetchAggregatedAboutToExpireItems()
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }
}
