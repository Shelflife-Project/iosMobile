import Foundation
import Observation

@MainActor
@Observable
class StorageDetailContext {
    var members: [StorageMemberInfo] = []
    var isLoadingMembers = false
    var isSyncingItems = false
    var errorMessage: String?

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    var acceptedMembers: [StorageMemberInfo] {
        members.filter { $0.accepted }
    }

    var invitedMembers: [StorageMemberInfo] {
        members.filter { !$0.accepted }
    }

    func refreshStorage(_ storage: Storage) async {
        guard let storageId = storage.serverId else { return }

        do {
            let remoteStorage = try await apiService.fetchStorage(id: storageId)
            storage.name = remoteStorage.name
            storage.owner = remoteStorage.owner
            await syncItems(for: storage)
        } catch {
            errorMessage = "Failed to refresh storage: \(error.localizedDescription)"
        }
    }

    func syncItems(for storage: Storage) async {
        guard let storageId = storage.serverId else { return }

        isSyncingItems = true
        defer { isSyncingItems = false }

        do {
            async let itemsFetch = apiService.fetchStorageItems(storageId: storageId)
            async let shoppingFetch = apiService.fetchShoppingItems(storageId: storageId)
            async let runningLowFetch = apiService.fetchRunningLowSettings(storageId: storageId)
            storage.items = try await itemsFetch
            storage.shoppingItems = try await shoppingFetch
            storage.runningLowSettings = try await runningLowFetch
        } catch {
            errorMessage = "Failed to sync items: \(error.localizedDescription)"
        }
    }

    func fetchMembers(for storage: Storage) async {
        guard let storageServerId = storage.serverId else {
            members = []
            seedOwnerAsMemberIfNeeded(storage)
            return
        }

        isLoadingMembers = true
        errorMessage = nil
        defer { isLoadingMembers = false }

        do {
            let fetched = try await apiService.fetchMembers(storageId: storageServerId)
            members = fetched
            seedOwnerAsMemberIfNeeded(storage)
        } catch {
            seedOwnerAsMemberIfNeeded(storage)
            errorMessage = "Failed to fetch members: \(error.localizedDescription)"
        }
    }

    func addItem(to storage: Storage, product: Product, expiresAt: Date) async {
        errorMessage = nil

        do {
            guard let storageId = storage.serverId, let productId = product.serverId else {
                throw APIError.invalidURL
            }

            let remoteItem = try await apiService.addStorageItem(
                storageId: storageId,
                productId: productId,
                expiresAt: expiresAt
            )

            _ = remoteItem
            await refreshStorage(storage)
        } catch {
            errorMessage = "Failed to add item: \(error.localizedDescription)"
        }
    }

    func removeMember(_ member: StorageMemberInfo, from storage: Storage) async {
        guard let storageServerId = storage.serverId else { return }

        do {
            try await apiService.removeMember(storageId: storageServerId, userId: member.userId)
            members.removeAll { $0.id == member.id }
        } catch {
            errorMessage = "Failed to remove member: \(error.localizedDescription)"
        }
    }

    func inviteMember(email: String, to storage: Storage) async {
        guard let storageServerId = storage.serverId else { return }

        do {
            let invited = try await apiService.inviteMember(storageId: storageServerId, email: email)
            members.append(invited)
        } catch {
            errorMessage = "Failed to invite member: \(error.localizedDescription)"
        }
    }

    func cancelInvite(_ invite: StorageMemberInfo, from storage: Storage) async {
        guard let storageServerId = storage.serverId else { return }

        do {
            try await apiService.removeMember(storageId: storageServerId, userId: invite.userId)
            members.removeAll { $0.id == invite.id }
        } catch {
            errorMessage = "Failed to cancel invitation: \(error.localizedDescription)"
        }
    }

    func deleteItems(at offsets: IndexSet, from storage: Storage) async {
        for index in offsets.sorted(by: >) {
            let item = storage.items[index]
            do {
                if let storageId = storage.serverId, let itemId = item.serverId {
                    try await apiService.deleteStorageItem(storageId: storageId, itemId: itemId)
                }
            } catch {
                errorMessage = "Failed to delete item: \(error.localizedDescription)"
            }
        }
        await syncItems(for: storage)
    }

    func deleteItem(_ item: StorageItem, from storage: Storage) async {
        do {
            if let storageId = storage.serverId, let itemId = item.serverId {
                try await apiService.deleteStorageItem(storageId: storageId, itemId: itemId)
            }
            await syncItems(for: storage)
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    func deleteShoppingItems(at offsets: IndexSet, from storage: Storage) async {
        for index in offsets.sorted(by: >) {
            let item = storage.shoppingItems[index]
            do {
                if let storageId = storage.serverId, let itemId = item.serverId {
                    try await apiService.deleteShoppingItem(storageId: storageId, itemId: itemId)
                }
            } catch {
                errorMessage = "Failed to delete shopping item: \(error.localizedDescription)"
            }
        }
        await syncItems(for: storage)
    }

    // MARK: - Per-Item Shopping List

    func addToShoppingList(product: Product, to storage: Storage, amount: Int = 1) async {
        guard let storageId = storage.serverId, let productId = product.serverId else { return }
        errorMessage = nil
        do {
            _ = try await apiService.addShoppingItem(storageId: storageId, productId: productId, amountToBuy: amount)
            await syncItems(for: storage)

            if pushNotificationsEnabled {
                await LocalNotificationService.shared.requestAuthorizationIfNeeded()
                await LocalNotificationService.shared.postShoppingListAddedNotification(
                    productName: product.name,
                    storageName: storage.name
                )
            }
        } catch {
            errorMessage = "Failed to add to shopping list: \(error.localizedDescription)"
        }
    }

    func removeFromShoppingList(product: Product, from storage: Storage) async {
        guard let storageId = storage.serverId else { return }
        guard let item = storage.shoppingItems.first(where: { $0.product?.serverId == product.serverId }),
              let itemId = item.serverId else { return }
        errorMessage = nil
        do {
            try await apiService.deleteShoppingItem(storageId: storageId, itemId: itemId)
            await syncItems(for: storage)
        } catch {
            errorMessage = "Failed to remove from shopping list: \(error.localizedDescription)"
        }
    }

    func updateShoppingListAmount(item: ShoppingListItem, in storage: Storage, amountToBuy: Int) async {
        guard let storageId = storage.serverId, let itemId = item.serverId else { return }
        errorMessage = nil
        do {
            _ = try await apiService.updateShoppingItemAmount(storageId: storageId, itemId: itemId, amountToBuy: amountToBuy)
            await syncItems(for: storage)
        } catch {
            errorMessage = "Failed to update shopping item amount: \(error.localizedDescription)"
        }
    }

    // MARK: - Per-Item Running Low

    func setRunningLow(product: Product, in storage: Storage, threshold: Int) async {
        guard let storageId = storage.serverId, let productId = product.serverId else { return }
        errorMessage = nil
        do {
            if let existing = storage.runningLowSettings.first(where: { $0.productId == productId }),
               let settingId = existing.serverId {
                let updated = try await apiService.updateRunningLowSetting(storageId: storageId, settingId: settingId, threshold: threshold)
                if let idx = storage.runningLowSettings.firstIndex(where: { $0.serverId == settingId }) {
                    storage.runningLowSettings[idx] = updated
                }
            } else {
                let created = try await apiService.createRunningLowSetting(storageId: storageId, productId: productId, threshold: threshold)
                storage.runningLowSettings.append(created)
            }
        } catch {
            errorMessage = "Failed to set running low: \(error.localizedDescription)"
        }
    }

    func removeRunningLow(product: Product, from storage: Storage) async {
        guard let storageId = storage.serverId else { return }
        guard let setting = storage.runningLowSettings.first(where: { $0.productId == product.serverId }),
              let settingId = setting.serverId else { return }
        errorMessage = nil
        do {
            try await apiService.deleteRunningLowSetting(storageId: storageId, settingId: settingId)
            storage.runningLowSettings.removeAll { $0.serverId == settingId }
        } catch {
            errorMessage = "Failed to remove running low setting: \(error.localizedDescription)"
        }
    }

    private func seedOwnerAsMemberIfNeeded(_ storage: Storage) {
        if let ownerId = storage.owner?.serverId,
           !members.contains(where: { $0.userId == ownerId }),
           let ownerName = storage.owner?.username {
            members.insert(
                StorageMemberInfo(id: -1, userId: ownerId, username: ownerName, accepted: true),
                at: 0
            )
        }
    }

    private var pushNotificationsEnabled: Bool {
        if UserDefaults.standard.object(forKey: "pushNotificationsEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "pushNotificationsEnabled")
    }
}
