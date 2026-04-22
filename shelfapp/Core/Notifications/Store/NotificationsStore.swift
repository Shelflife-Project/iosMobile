import Foundation
import Observation

@MainActor
@Observable
final class NotificationsStore {
    var notificationsState: Loadable<NotificationsPayload> = .idle

    var invites: [PendingInviteInfo] { notificationsState.value?.invites ?? [] }
    var runningLowItems: [RunningLowNotification] { notificationsState.value?.runningLowItems ?? [] }
    var aboutToExpireItems: [StorageItem] { notificationsState.value?.aboutToExpireItems ?? [] }

    var isLoading: Bool { notificationsState.isLoading }
    var errorMessage: String? {
        get { notificationsState.error?.localizedDescription }
        set {
            if let msg = newValue { notificationsState = .failed(.serverMessage(msg)) }
            else if case .failed = notificationsState { notificationsState = .idle }
        }
    }

    init() {}

    func fetchInvites() async {
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let dtos = try await NotificationsAPI.fetchPendingInvites(token: token)
            let newInvites = dtos.map { dto in
                PendingInviteInfo(id: dto.id, storageName: dto.storage?.name ?? "Unknown", storageId: dto.storage?.id ?? 0, invitedBy: dto.user.username)
            }
            var payload = notificationsState.value ?? NotificationsPayload()
            payload.invites = newInvites
            notificationsState = .loaded(payload)
        } catch {
            notificationsState = .failed(.serverMessage("Failed to fetch invites: \(error.localizedDescription)"))
        }
    }

    func fetchAll() async {
        notificationsState = .loading
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let invitesDtos = try await NotificationsAPI.fetchPendingInvites(token: token)
            let fetchedInvites = invitesDtos.map { dto in
                PendingInviteInfo(id: dto.id, storageName: dto.storage?.name ?? "Unknown", storageId: dto.storage?.id ?? 0, invitedBy: dto.user.username)
            }
            // Note: running-low and about-to-expire endpoints not yet implemented (BP-2).
            notificationsState = .loaded(NotificationsPayload(invites: fetchedInvites, runningLowItems: [], aboutToExpireItems: []))
        } catch {
            notificationsState = .failed(.serverMessage("Failed to fetch notifications: \(error.localizedDescription)"))
        }
    }

    func refreshAll() async { await fetchAll() }

    func acceptInvite(_ invite: PendingInviteInfo, storageService: StoragesStore) async {
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            try await NotificationsAPI.acceptInvite(token: token, inviteId: invite.id)
            var payload = notificationsState.value ?? NotificationsPayload()
            payload.invites.removeAll { $0.id == invite.id }
            notificationsState = .loaded(payload)
            await storageService.fetch()
        } catch {
            notificationsState = .failed(.serverMessage("Failed to accept invite: \(error.localizedDescription)"))
        }
    }

    func declineInvite(_ invite: PendingInviteInfo) async {
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            try await NotificationsAPI.declineInvite(token: token, inviteId: invite.id)
            var payload = notificationsState.value ?? NotificationsPayload()
            payload.invites.removeAll { $0.id == invite.id }
            notificationsState = .loaded(payload)
        } catch {
            notificationsState = .failed(.serverMessage("Failed to decline invite: \(error.localizedDescription)"))
        }
    }

    func addRunningLowItemToShoppingList(storageId: Int, productId: Int, shoppingService: ShoppingListStore) async {
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            _ = try await ShoppingListAPI.addItem(token: token, storageId: storageId, productId: productId, amountToBuy: 1)
            await shoppingService.fetchAggregated()
        } catch {
            notificationsState = .failed(.serverMessage("Failed to add running low item to shopping list: \(error.localizedDescription)"))
        }
    }

    func deleteExpiredItem(itemId: Int, storageId: Int) async {
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            try await StoragesAPI.deleteItem(token: token, storageId: storageId, itemId: itemId)
            var payload = notificationsState.value ?? NotificationsPayload()
            payload.aboutToExpireItems = []
            notificationsState = .loaded(payload)
        } catch {
            notificationsState = .failed(.serverMessage("Failed to delete item: \(error.localizedDescription)"))
        }
    }
}

// MARK: - Payload container

struct NotificationsPayload {
    var invites: [PendingInviteInfo] = []
    var runningLowItems: [RunningLowNotification] = []
    var aboutToExpireItems: [StorageItem] = []
}

typealias NotificationsService = NotificationsStore
