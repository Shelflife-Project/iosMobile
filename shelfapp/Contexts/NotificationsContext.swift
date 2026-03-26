import Foundation
import Observation

@MainActor
@Observable
class NotificationsContext {
    var invites: [PendingInviteInfo] = []
    var runningLowItems: [RunningLowNotification] = []
    var aboutToExpireItems: [StorageItem] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func fetchInvites() async {
        do {
            invites = try await apiService.fetchPendingInvites()
        } catch {
            errorMessage = "Failed to fetch invites: \(error.localizedDescription)"
        }
    }

    func fetchAll() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let invitesFetch = apiService.fetchPendingInvites()
            async let runningLowFetch = apiService.fetchAggregatedRunningLowNotifications()
            async let aboutToExpireFetch = apiService.fetchAggregatedAboutToExpireItems()

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

    func acceptInvite(_ invite: PendingInviteInfo, storageContext: StorageContext) async {
        errorMessage = nil

        do {
            try await apiService.acceptInvite(inviteId: invite.id)
            invites.removeAll { $0.id == invite.id }
            await storageContext.fetch()
        } catch {
            errorMessage = "Failed to accept invite: \(error.localizedDescription)"
        }
    }

    func declineInvite(_ invite: PendingInviteInfo) async {
        errorMessage = nil

        do {
            try await apiService.declineInvite(inviteId: invite.id)
            invites.removeAll { $0.id == invite.id }
        } catch {
            errorMessage = "Failed to decline invite: \(error.localizedDescription)"
        }
    }

    func addRunningLowToShoppingList(_ item: RunningLowNotification, shoppingListContext: ShoppingListContext) async {
        errorMessage = nil

        do {
            guard let storageId = item.storage.serverId, let productId = item.product.serverId else {
                throw APIError.invalidURL
            }

            let amountToBuy = max(1, item.runningLowAt - item.amount + 1)
            _ = try await apiService.addShoppingItem(storageId: storageId, productId: productId, amountToBuy: amountToBuy)
        } catch {
            errorMessage = "Failed to add item to shopping list: \(error.localizedDescription)"
        }

        await shoppingListContext.fetchAggregated()

        do {
            runningLowItems = try await apiService.fetchAggregatedRunningLowNotifications()
        } catch {
            errorMessage = "Failed to refresh running low notifications: \(error.localizedDescription)"
        }
    }

    func deleteExpiredItem(_ item: StorageItem) async {
        errorMessage = nil

        do {
            guard let storageId = item.storage?.serverId, let itemId = item.serverId else {
                throw APIError.invalidURL
            }

            try await apiService.deleteStorageItem(storageId: storageId, itemId: itemId)
            aboutToExpireItems = try await apiService.fetchAggregatedAboutToExpireItems()
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }
}
