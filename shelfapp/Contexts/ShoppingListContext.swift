import Observation
import SwiftData
import Foundation

@MainActor
@Observable
class ShoppingListContext {
    var items: [ShoppingListItem] = []
    var isLoading = false
    var errorMessage: String?
    var selectedStorageId: Int?

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func loadLocal(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ShoppingListItem>()
            let allItems = try context.fetch(descriptor)
            if let selectedStorageId {
                items = allItems.filter { $0.storage?.serverId == selectedStorageId }
            } else {
                items = allItems
            }
        } catch {
            errorMessage = "Failed to load shopping items: \(error.localizedDescription)"
        }
    }

    func fetchItems(storageId: Int, context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        selectedStorageId = storageId
        defer { isLoading = false }

        do {
            let remoteItems = try await apiService.fetchShoppingItems(storageId: storageId)
            try syncPersistedItems(remoteItems, forStorageId: storageId, context: context)

            loadLocal(context: context)
        } catch {
            errorMessage = "Failed to fetch shopping items: \(error.localizedDescription)"
            loadLocal(context: context)
        }
    }

    func addItem(storage: Storage, product: Product, amountToBuy: Int, context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let storageId = storage.serverId, let productId = product.serverId else {
                throw APIError.invalidURL
            }

            let item = try await apiService.addShoppingItem(
                storageId: storageId,
                productId: productId,
                amountToBuy: amountToBuy
            )

            if let existing = storage.shoppingItems.first(where: { $0.serverId == item.serverId }) {
                existing.amountToBuy = item.amountToBuy
                existing.product = product
                existing.storage = storage
            } else {
                item.storage = storage
                item.product = product
                storage.shoppingItems.append(item)
                context.insert(item)
            }

            try context.save()
            loadLocal(context: context)
        } catch {
            errorMessage = "Failed to add shopping item: \(error.localizedDescription)"
        }
    }

    func deleteItem(_ item: ShoppingListItem, from storage: Storage, context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let storageId = storage.serverId, let itemId = item.serverId {
                try await apiService.deleteShoppingItem(storageId: storageId, itemId: itemId)
            }
            storage.shoppingItems.removeAll { $0.id == item.id }
            context.delete(item)
            try context.save()
            loadLocal(context: context)
        } catch {
            errorMessage = "Failed to delete shopping item: \(error.localizedDescription)"
        }
    }

    private func syncPersistedItems(_ remoteItems: [ShoppingListItem], forStorageId storageId: Int, context: ModelContext) throws {
        guard let storage = try context.fetch(FetchDescriptor<Storage>()).first(where: { $0.serverId == storageId }) else {
            return
        }

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
                existing.storage = storage
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
            if let localId = local.serverId {
                if !remoteServerIds.contains(localId) {
                    storage.shoppingItems.removeAll { $0.id == local.id }
                    context.delete(local)
                }
            } else {
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
