import Foundation
import Observation

@MainActor
@Observable
final class StorageDetailStore {
    var membersState: Loadable<[StorageMemberInfo]> = .idle
    var itemsState: Loadable<[StorageItem]> = .idle
    var actionError: String?

    var members: [StorageMemberInfo] { membersState.value ?? [] }
    var isLoadingMembers: Bool { membersState.isLoading }
    var isLoadingItems: Bool { itemsState.isLoading }

    var isLoading: Bool { membersState.isLoading || itemsState.isLoading }
    var errorMessage: String? {
        get { actionError ?? membersState.error?.localizedDescription ?? itemsState.error?.localizedDescription }
        set {
            actionError = newValue
            if newValue == nil {
                if case .failed = membersState { membersState = .idle }
                if case .failed = itemsState { itemsState = .idle }
            }
        }
    }

    var acceptedMembers: [StorageMemberInfo] { members.filter { $0.accepted } }
    var invitedMembers: [StorageMemberInfo] { members.filter { !$0.accepted } }

    init() {}

    func refreshStorage(_ storage: Storage) async {
        guard let storageId = storage.id else { return }
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let remoteStorage = try await StorageDetailAPI.fetchStorage(token: token, id: storageId)
            storage.name = remoteStorage.toDomain().name
            storage.owner = remoteStorage.toDomain().owner
            await loadItems(for: storage)
        } catch {
            itemsState = .failed(.serverMessage("Failed to refresh storage: \(error.localizedDescription)"))
        }
    }

    func loadItems(for storage: Storage) async {
        guard let storageId = storage.id else { return }
        itemsState = .loading

        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            async let itemsFetch = StoragesAPI.fetchItems(token: token, storageId: storageId)
            async let shoppingFetch = StorageDetailAPI.fetchShoppingItems(token: token, storageId: storageId)
            async let runningLowFetch = StoragesAPI.fetchRunningLowSettings(token: token, storageId: storageId)
            storage.items = try await itemsFetch.map { $0.toDomain() }
            storage.shoppingItems = try await shoppingFetch.map { $0.toDomain() }
            storage.runningLowSettings = try await runningLowFetch.map { $0.toDomain() }
            itemsState = .loaded(storage.items)
        } catch {
            itemsState = .failed(.serverMessage("Failed to load items: \(error.localizedDescription)"))
        }
    }

    func fetchMembers(for storage: Storage) async {
        guard let storageServerId = storage.id else {
            membersState = .loaded([])
            seedOwnerAsMemberIfNeeded(storage)
            return
        }

        membersState = .loading
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let fetched = try await StorageDetailAPI.fetchMembers(token: token, storageId: storageServerId)
            var result = fetched.map { dto in
                StorageMemberInfo(id: dto.id, userId: dto.user.id, username: dto.user.username, accepted: dto.isAccepted)
            }
            if let ownerId = storage.owner?.id,
               !result.contains(where: { $0.userId == ownerId }),
               let ownerName = storage.owner?.username {
                result.insert(StorageMemberInfo(id: -1, userId: ownerId, username: ownerName, accepted: true), at: 0)
            }
            membersState = .loaded(result)
        } catch {
            seedOwnerAsMemberIfNeeded(storage)
            membersState = .failed(.serverMessage("Failed to fetch members: \(error.localizedDescription)"))
        }
    }

    func addItem(to storage: Storage, product: Product, expiresAt: Date) async {
        do {
            guard let storageId = storage.id, let productId = product.id else { throw APIError.invalidURL }
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dto = try await StorageDetailAPI.addItem(token: token, storageId: storageId, productId: productId, expiresAt: formatter.string(from: expiresAt))
            storage.items.append(StorageItem(from: dto))
            itemsState = .loaded(storage.items)
        } catch {
            actionError = "Failed to add item: \(error.localizedDescription)"
        }
    }

    func removeMember(_ member: StorageMemberInfo, from storage: Storage) async {
        guard let storageServerId = storage.id else { return }
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            try await StorageDetailAPI.removeMember(token: token, storageId: storageServerId, userId: member.userId)
            if var list = membersState.value {
                list.removeAll { $0.id == member.id }
                membersState = .loaded(list)
            }
        } catch {
            actionError = "Failed to remove member: \(error.localizedDescription)"
        }
    }

    func inviteMember(email: String, to storage: Storage) async {
        guard let storageServerId = storage.id else { return }
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let invited = try await StorageDetailAPI.inviteMember(token: token, storageId: storageServerId, email: email)
            let info = StorageMemberInfo(id: invited.id, userId: invited.user.id, username: invited.user.username, accepted: invited.isAccepted)
            var list = membersState.value ?? []
            list.append(info)
            membersState = .loaded(list)
        } catch {
            actionError = "Failed to invite member: \(error.localizedDescription)"
        }
    }

    func cancelInvite(_ invite: StorageMemberInfo, from storage: Storage) async {
        await removeMember(invite, from: storage)
    }

    func deleteItem(_ item: StorageItem, from storage: Storage) async {
        do {
            if let storageId = storage.id, let itemId = item.id {
                guard let token = sharedJWTToken else { throw APIError.unauthorized }
                try await StorageDetailAPI.deleteItem(token: token, storageId: storageId, itemId: itemId)
            }
            storage.items.removeAll { $0.id == item.id }
            itemsState = .loaded(storage.items)
        } catch {
            actionError = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    func deleteItems(at offsets: IndexSet, from storage: Storage) async {
        for offset in offsets {
            guard storage.items.indices.contains(offset) else { continue }
            let item = storage.items[offset]
            await deleteItem(item, from: storage)
        }
    }

    func addToShoppingList(product: Product, to storage: Storage, amount: Int = 1) async {
        guard let storageId = storage.id, let productId = product.id else { return }
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let dto = try await StorageDetailAPI.addShoppingItem(token: token, storageId: storageId, productId: productId, amountToBuy: amount)
            storage.shoppingItems.append(ShoppingListItem(from: dto))
            itemsState = .loaded(storage.items)
            if pushNotificationsEnabled {
                await LocalNotificationService.shared.requestAuthorizationIfNeeded()
                await LocalNotificationService.shared.postShoppingListAddedNotification(productName: product.name, storageName: storage.name)
            }
        } catch {
            actionError = "Failed to add to shopping list: \(error.localizedDescription)"
        }
    }

    func removeFromShoppingList(product: Product, from storage: Storage) async {
        guard let storageId = storage.id else { return }
        guard let item = storage.shoppingItems.first(where: { $0.product?.id == product.id }),
              let itemId = item.id else { return }
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            try await StorageDetailAPI.deleteShoppingItem(token: token, storageId: storageId, itemId: itemId)
            storage.shoppingItems.removeAll { $0.id == itemId }
            itemsState = .loaded(storage.items)
        } catch {
            actionError = "Failed to remove from shopping list: \(error.localizedDescription)"
        }
    }

    func updateShoppingListAmount(item: ShoppingListItem, in storage: Storage, amountToBuy: Int) async {
        guard let storageId = storage.id, let itemId = item.id else { return }
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let dto = try await StorageDetailAPI.updateShoppingItem(token: token, storageId: storageId, itemId: itemId, amountToBuy: amountToBuy)
            if let index = storage.shoppingItems.firstIndex(where: { $0.id == itemId }) {
                storage.shoppingItems[index] = ShoppingListItem(from: dto)
            }
            itemsState = .loaded(storage.items)
        } catch {
            actionError = "Failed to update shopping item: \(error.localizedDescription)"
        }
    }

    func completeShoppingItem(_ item: ShoppingListItem, in storage: Storage) async {
        guard let storageId = storage.id, let itemId = item.id else { return }
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            // Note: Complete shopping item endpoint not yet implemented (BP-3). Deletes instead.
            try await StorageDetailAPI.deleteShoppingItem(token: token, storageId: storageId, itemId: itemId)
            storage.shoppingItems.removeAll { $0.id == itemId }
            itemsState = .loaded(storage.items)
        } catch {
            actionError = "Failed to complete shopping item: \(error.localizedDescription)"
        }
    }

    func setRunningLow(product: Product, in storage: Storage, threshold: Int) async {
        guard let storageId = storage.id, let productId = product.id else { return }
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let existing = storage.runningLowSettings.first { $0.productId == productId }
            let dto: RunningLowSettingDTO
            if let settingId = existing?.settingId {
                dto = try await StoragesAPI.editRunningLowSetting(token: token, storageId: storageId, settingId: settingId, threshold: threshold)
            } else {
                dto = try await StoragesAPI.createRunningLowSetting(token: token, storageId: storageId, productId: productId, threshold: threshold)
            }
            let updated = dto.toDomain()
            if let index = storage.runningLowSettings.firstIndex(where: { $0.productId == productId }) {
                storage.runningLowSettings[index] = updated
            } else {
                storage.runningLowSettings.append(updated)
            }
            itemsState = .loaded(storage.items)
        } catch {
            actionError = "Failed to set running low: \(error.localizedDescription)"
        }
    }

    func removeRunningLow(product: Product, from storage: Storage) async {
        guard let storageId = storage.id, let productId = product.id else { return }
        guard let setting = storage.runningLowSettings.first(where: { $0.productId == productId }),
              let settingId = setting.settingId else { return }
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            try await StoragesAPI.deleteRunningLowSetting(token: token, storageId: storageId, settingId: settingId)
            storage.runningLowSettings.removeAll { $0.productId == productId }
            itemsState = .loaded(storage.items)
        } catch {
            actionError = "Failed to remove running low: \(error.localizedDescription)"
        }
    }

    private func seedOwnerAsMemberIfNeeded(_ storage: Storage) {
        if let ownerId = storage.owner?.id,
           !members.contains(where: { $0.userId == ownerId }),
           let ownerName = storage.owner?.username {
            var list = membersState.value ?? []
            list.insert(StorageMemberInfo(id: -1, userId: ownerId, username: ownerName, accepted: true), at: 0)
            membersState = .loaded(list)
        }
    }

    private var pushNotificationsEnabled: Bool {
        if UserDefaults.standard.object(forKey: "pushNotificationsEnabled") == nil { return true }
        return UserDefaults.standard.bool(forKey: "pushNotificationsEnabled")
    }
}

typealias StorageDetailService = StorageDetailStore
