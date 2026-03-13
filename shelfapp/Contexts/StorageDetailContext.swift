import Observation
import SwiftData

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

    func syncItems(for storage: Storage, context: ModelContext) async {
        guard let storageId = storage.serverId else { return }

        isSyncingItems = true
        defer { isSyncingItems = false }

        do {
            let remoteItems = try await apiService.fetchStorageItems(storageId: storageId)
            let remoteShopping = try await apiService.fetchShoppingItems(storageId: storageId)

            try syncPersistedStorageItems(remoteItems, for: storage, context: context)
            try syncPersistedShoppingItems(remoteShopping, for: storage, context: context)
        } catch {
            errorMessage = "Failed to sync items: \(error.localizedDescription)"
        }
    }

    func fetchMembers(for storage: Storage) async {
        guard let storageServerId = storage.serverId else {
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

    func addItem(to storage: Storage, product: Product, expiresAt: Date, context: ModelContext) async {
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

            if let existing = storage.items.first(where: { $0.serverId == remoteItem.serverId }) {
                existing.product = product
                existing.expiresAt = remoteItem.expiresAt
                existing.createdAt = remoteItem.createdAt
            } else {
                remoteItem.product = product
                storage.items.append(remoteItem)
                context.insert(remoteItem)
            }

            try context.save()
        } catch {
            do {
                let localItem = StorageItem(product: product, expiresAt: expiresAt)
                storage.items.append(localItem)
                context.insert(localItem)
                try context.save()
            } catch {
                errorMessage = "Failed to add item: \(error.localizedDescription)"
            }
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

    func deleteItems(at offsets: IndexSet, from storage: Storage, context: ModelContext) async {
        for index in offsets {
            let item = storage.items[index]
            do {
                if let storageId = storage.serverId, let itemId = item.serverId {
                    try await apiService.deleteStorageItem(storageId: storageId, itemId: itemId)
                }
                storage.items.removeAll { $0.id == item.id }
                context.delete(item)
                try context.save()
            } catch {
                errorMessage = "Failed to delete item: \(error.localizedDescription)"
            }
        }
    }

    func deleteShoppingItems(at offsets: IndexSet, from storage: Storage, context: ModelContext) async {
        for index in offsets {
            let item = storage.shoppingItems[index]
            do {
                if let storageId = storage.serverId, let itemId = item.serverId {
                    try await apiService.deleteShoppingItem(storageId: storageId, itemId: itemId)
                }
                storage.shoppingItems.removeAll { $0.id == item.id }
                context.delete(item)
                try context.save()
            } catch {
                errorMessage = "Failed to delete shopping item: \(error.localizedDescription)"
            }
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

    private func syncPersistedStorageItems(_ remoteItems: [StorageItem], for storage: Storage, context: ModelContext) throws {
        let localItems = storage.items
        var localByServerId: [Int: StorageItem] = [:]

        for item in localItems {
            if let serverId = item.serverId {
                localByServerId[serverId] = item
            }
        }

        let remoteServerIds = Set(remoteItems.compactMap { $0.serverId })

        for remote in remoteItems {
            guard let remoteId = remote.serverId else { continue }

            if let existing = localByServerId[remoteId] {
                existing.expiresAt = remote.expiresAt
                existing.createdAt = remote.createdAt
                if let remoteProductId = remote.product?.serverId,
                   let localProduct = try findProduct(byServerId: remoteProductId, context: context) {
                    existing.product = localProduct
                }
            } else {
                if let remoteProductId = remote.product?.serverId,
                   let localProduct = try findProduct(byServerId: remoteProductId, context: context) {
                    remote.product = localProduct
                }
                storage.items.append(remote)
                context.insert(remote)
            }
        }

        for local in localItems {
            guard let localId = local.serverId else { continue }
            if !remoteServerIds.contains(localId) {
                storage.items.removeAll { $0.id == local.id }
                context.delete(local)
            }
        }

        try context.save()
    }

    private func syncPersistedShoppingItems(_ remoteItems: [ShoppingListItem], for storage: Storage, context: ModelContext) throws {
        let localItems = storage.shoppingItems
        var localByServerId: [Int: ShoppingListItem] = [:]

        for item in localItems {
            if let serverId = item.serverId {
                localByServerId[serverId] = item
            }
        }

        let remoteServerIds = Set(remoteItems.compactMap { $0.serverId })

        for remote in remoteItems {
            guard let remoteId = remote.serverId else { continue }

            if let existing = localByServerId[remoteId] {
                existing.amountToBuy = remote.amountToBuy
                if let remoteProductId = remote.product?.serverId,
                   let localProduct = try findProduct(byServerId: remoteProductId, context: context) {
                    existing.product = localProduct
                }
            } else {
                if let remoteProductId = remote.product?.serverId,
                   let localProduct = try findProduct(byServerId: remoteProductId, context: context) {
                    remote.product = localProduct
                }
                remote.storage = storage
                storage.shoppingItems.append(remote)
                context.insert(remote)
            }
        }

        for local in localItems {
            guard let localId = local.serverId else { continue }
            if !remoteServerIds.contains(localId) {
                storage.shoppingItems.removeAll { $0.id == local.id }
                context.delete(local)
            }
        }

        try context.save()
    }

    private func findProduct(byServerId serverId: Int, context: ModelContext) throws -> Product? {
        try context.fetch(FetchDescriptor<Product>()).first(where: { $0.serverId == serverId })
    }
}
