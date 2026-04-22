import Foundation
import Observation

@MainActor
@Observable
final class ShoppingListStore {
    var itemsState: Loadable<[ShoppingListItem]> = .idle

    var items: [ShoppingListItem] { itemsState.value ?? [] }
    var isLoading: Bool { itemsState.isLoading }
    var errorMessage: String? {
        get { itemsState.error?.localizedDescription }
        set {
            if let msg = newValue { itemsState = .failed(.serverMessage(msg)) }
            else if case .failed = itemsState { itemsState = .idle }
        }
    }

    init() {}

    func fetchAggregated() async {
        itemsState = .loading
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let dtos = try await ShoppingListAPI.fetchAggregated(token: token)
            itemsState = .loaded(dtos.map { $0.toDomain() })
        } catch {
            itemsState = .failed(.serverMessage("Failed to fetch shopping items: \(error.localizedDescription)"))
        }
    }

    func fetchItems(storageId: Int) async {
        itemsState = .loading
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let dtos = try await ShoppingListAPI.fetchByStorage(token: token, storageId: storageId)
            itemsState = .loaded(dtos.map { $0.toDomain() })
        } catch {
            itemsState = .failed(.serverMessage("Failed to fetch shopping items: \(error.localizedDescription)"))
        }
    }

    func addItem(storage: Storage, product: Product, amountToBuy: Int) async {
        do {
            guard let storageId = storage.id, let productId = product.id else { throw APIError.invalidURL }
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            _ = try await ShoppingListAPI.addItem(token: token, storageId: storageId, productId: productId, amountToBuy: amountToBuy)
            let dtos = try await ShoppingListAPI.fetchAggregated(token: token)
            itemsState = .loaded(dtos.map { $0.toDomain() })
        } catch {
            itemsState = .failed(.serverMessage("Failed to add shopping item: \(error.localizedDescription)"))
        }
    }

    func updateItemAmount(_ item: ShoppingListItem, amountToBuy: Int) async {
        do {
            guard let itemId = item.id else { throw APIError.invalidURL }
            let storageId = try await resolveStorageId(for: item)
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            _ = try await ShoppingListAPI.updateItem(token: token, storageId: storageId, itemId: itemId, amountToBuy: amountToBuy)
            let dtos = try await ShoppingListAPI.fetchAggregated(token: token)
            itemsState = .loaded(dtos.map { $0.toDomain() })
        } catch {
            itemsState = .failed(.serverMessage("Failed to update shopping item: \(error.localizedDescription)"))
        }
    }

    func completeItem(_ item: ShoppingListItem) async {
        do {
            guard let itemId = item.id else { throw APIError.invalidURL }
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            do {
                let storageId = try await resolveStorageId(for: item)
                _ = try await ShoppingListAPI.deleteItem(token: token, storageId: storageId, itemId: itemId)
            } catch APIError.serverError(let statusCode) where statusCode == 403 {
                let refreshed = try await refreshedItem(for: itemId)
                let storageId = try await resolveStorageId(for: refreshed.toDomain())
                if let productId = refreshed.product?.id {
                    let amount = max(1, refreshed.amountToBuy)
                    let expiresAtStr: String = {
                        guard let delta = refreshed.product?.expirationDaysDelta, delta > 0 else { return "" }
                        let expiry = Calendar.current.date(byAdding: .day, value: delta, to: Date()) ?? Date()
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        return formatter.string(from: expiry)
                    }()
                    for _ in 0..<amount {
                        _ = try await StoragesAPI.addItem(token: token, storageId: storageId, productId: productId, expiresAt: expiresAtStr)
                    }
                    try await ShoppingListAPI.deleteItem(token: token, storageId: storageId, itemId: itemId)
                } else {
                    throw APIError.invalidURL
                }
            }
            let dtos = try await ShoppingListAPI.fetchAggregated(token: token)
            itemsState = .loaded(dtos.map { $0.toDomain() })
        } catch {
            itemsState = .failed(.serverMessage("Failed to complete shopping item: \(error.localizedDescription)"))
        }
    }

    func deleteItem(_ item: ShoppingListItem) async {
        do {
            guard let itemId = item.id else { throw APIError.invalidURL }
            let storageId = try await resolveStorageId(for: item)
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            try await ShoppingListAPI.deleteItem(token: token, storageId: storageId, itemId: itemId)
            let dtos = try await ShoppingListAPI.fetchAggregated(token: token)
            itemsState = .loaded(dtos.map { $0.toDomain() })
        } catch {
            itemsState = .failed(.serverMessage("Failed to delete shopping item: \(error.localizedDescription)"))
        }
    }

    private func resolveStorageId(for item: ShoppingListItem) async throws -> Int {
        if let storageId = item.storage?.id { return storageId }
        guard let itemId = item.id else { throw APIError.invalidURL }
        guard let token = sharedJWTToken else { throw APIError.unauthorized }
        let latest = try await ShoppingListAPI.fetchAggregated(token: token)
        itemsState = .loaded(latest.map { $0.toDomain() })
        if let refreshed = latest.first(where: { $0.id == itemId }),
           let storageId = refreshed.storage?.id { return storageId }
        throw APIError.invalidURL
    }

    private func refreshedItem(for itemId: Int) async throws -> ShoppingListItemDTO {
        guard let token = sharedJWTToken else { throw APIError.unauthorized }
        let latest = try await ShoppingListAPI.fetchAggregated(token: token)
        itemsState = .loaded(latest.map { $0.toDomain() })
        guard let refreshed = latest.first(where: { $0.id == itemId }) else { throw APIError.notFound }
        return refreshed
    }
}

typealias ShoppingListService = ShoppingListStore
