import Observation
import Foundation

@MainActor
@Observable
class ShoppingListStore {
    var items: [ShoppingListItem] = []
    var isLoading = false
    var errorMessage: String?

    private let api: ShoppingListAPI

    init(api: ShoppingListAPI = DefaultShoppingListAPI()) {
        self.api = api
    }

    func fetchAggregated() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            items = try await api.fetchAggregatedShoppingItems()
        } catch {
            errorMessage = "Failed to fetch shopping items: \(error.localizedDescription)"
            items = []
        }
    }

    private func refreshItemsDirect() async throws {
        items = try await api.fetchAggregatedShoppingItems()
    }

    private func resolveStorageId(for item: ShoppingListItem) async throws -> Int {
        if let storageId = item.storage?.serverId {
            return storageId
        }

        guard let itemId = item.serverId else {
            throw APIError.invalidURL
        }

        let latest = try await api.fetchAggregatedShoppingItems()
        items = latest

        if let refreshed = latest.first(where: { $0.serverId == itemId }),
           let storageId = refreshed.storage?.serverId {
            return storageId
        }

        throw APIError.invalidURL
    }

    private func refreshedItem(for itemId: Int) async throws -> ShoppingListItem {
        let latest = try await api.fetchAggregatedShoppingItems()
        items = latest

        guard let refreshed = latest.first(where: { $0.serverId == itemId }) else {
            throw APIError.notFound
        }

        return refreshed
    }

    func fetchItems(storageId: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            items = try await api.fetchShoppingItems(storageId: storageId)
        } catch {
            errorMessage = "Failed to fetch shopping items: \(error.localizedDescription)"
            items = []
        }
    }

    func addItem(storage: Storage, product: Product, amountToBuy: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let storageId = storage.serverId, let productId = product.serverId else {
                throw APIError.invalidURL
            }

            let item = try await api.addShoppingItem(
                storageId: storageId,
                productId: productId,
                amountToBuy: amountToBuy
            )
            _ = item
            await fetchAggregated()
        } catch {
            errorMessage = "Failed to add shopping item: \(error.localizedDescription)"
        }
    }

    func updateItemAmount(_ item: ShoppingListItem, amountToBuy: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let itemId = item.serverId else {
                throw APIError.invalidURL
            }

            do {
                let storageId = try await resolveStorageId(for: item)
                _ = try await api.updateShoppingItemAmount(storageId: storageId, itemId: itemId, amountToBuy: amountToBuy)
            } catch APIError.serverError(let statusCode) where statusCode == 403 {
                let refreshed = try await refreshedItem(for: itemId)
                let storageId = try await resolveStorageId(for: refreshed)
                _ = try await api.updateShoppingItemAmount(storageId: storageId, itemId: itemId, amountToBuy: amountToBuy)
            }

            try await refreshItemsDirect()
        } catch {
            errorMessage = "Failed to update shopping item: \(error.localizedDescription)"
        }
    }

    func completeItem(_ item: ShoppingListItem) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let itemId = item.serverId else {
                throw APIError.invalidURL
            }

            do {
                let storageId = try await resolveStorageId(for: item)
                try await api.completeShoppingItem(storageId: storageId, itemId: itemId)
            } catch APIError.serverError(let statusCode) where statusCode == 403 {
                let refreshed = try await refreshedItem(for: itemId)
                let storageId = try await resolveStorageId(for: refreshed)

                if let productId = refreshed.product?.serverId {
                    let amount = max(1, refreshed.amountToBuy)
                    for _ in 0..<amount {
                        _ = try await api.addStorageItem(storageId: storageId, productId: productId, expiresAt: nil)
                    }
                    try await api.deleteShoppingItem(storageId: storageId, itemId: itemId)
                } else {
                    throw APIError.invalidURL
                }
            }

            try await refreshItemsDirect()
        } catch {
            errorMessage = "Failed to add shopping item to storage: \(error.localizedDescription)"
        }
    }

    func deleteItem(_ item: ShoppingListItem) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let itemId = item.serverId else {
                throw APIError.invalidURL
            }

            do {
                let storageId = try await resolveStorageId(for: item)
                try await api.deleteShoppingItem(storageId: storageId, itemId: itemId)
            } catch APIError.serverError(let statusCode) where statusCode == 403 {
                let refreshed = try await refreshedItem(for: itemId)
                let storageId = try await resolveStorageId(for: refreshed)
                try await api.deleteShoppingItem(storageId: storageId, itemId: itemId)
            }

            try await refreshItemsDirect()
        } catch {
            errorMessage = "Failed to delete shopping item: \(error.localizedDescription)"
        }
    }
}
