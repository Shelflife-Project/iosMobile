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
            storage.items = try await apiService.fetchStorageItems(storageId: storageId)
            storage.shoppingItems = try await apiService.fetchShoppingItems(storageId: storageId)
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
}
