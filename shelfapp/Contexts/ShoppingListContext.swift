import Observation
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

    func sync(from storages: [Storage]) {
        let allItems = storages.flatMap { $0.shoppingItems }
        if let selectedStorageId {
            items = allItems.filter { $0.storage?.serverId == selectedStorageId }
        } else {
            items = allItems
        }
    }

    func fetchItems(storageId: Int, storageContext: StorageContext) async {
        isLoading = true
        errorMessage = nil
        selectedStorageId = storageId
        defer { isLoading = false }

        await storageContext.fetch()
        sync(from: storageContext.storages)
    }

    func addItem(storage: Storage, product: Product, amountToBuy: Int, storageContext: StorageContext) async {
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
            _ = item
            await storageContext.fetch()
            sync(from: storageContext.storages)
        } catch {
            errorMessage = "Failed to add shopping item: \(error.localizedDescription)"
        }
    }

    func deleteItem(_ item: ShoppingListItem, from storage: Storage, storageContext: StorageContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let storageId = storage.serverId, let itemId = item.serverId {
                try await apiService.deleteShoppingItem(storageId: storageId, itemId: itemId)
            }
            await storageContext.fetch()
            sync(from: storageContext.storages)
        } catch {
            errorMessage = "Failed to delete shopping item: \(error.localizedDescription)"
        }
    }
}
