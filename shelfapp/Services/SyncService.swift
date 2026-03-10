import Foundation
import SwiftData

class SyncService {
    static let shared = SyncService()

    private let apiService = APIService.shared

    // MARK: - Storage Sync

    func syncStorages(in context: ModelContext) async throws {
        do {
            let remoteStorages = try await apiService.fetchStorages()

            // Clear local storages and insert remote ones
            try context.delete(model: Storage.self)

            for remoteStorage in remoteStorages {
                context.insert(remoteStorage)
            }

            try context.save()
        } catch {
            print("Failed to sync storages: \(error.localizedDescription)")
            throw error
        }
    }

    func syncStorageItems(for storage: Storage, in context: ModelContext) async throws {
        guard let storageId = storage.serverId else {
            print("Cannot sync items: storage has no serverId")
            return
        }
        do {
            let remoteItems = try await apiService.fetchStorageItems(storageId: storageId)

            // Clear local storage items and insert remote ones
            storage.items.removeAll()
            for remoteItem in remoteItems {
                storage.items.append(remoteItem)
            }

            try context.save()
        } catch {
            print("Failed to sync storage items: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Create Operations

    func createStorageAndSync(name: String, in context: ModelContext) async throws -> Storage {
        do {
            let remoteStorage = try await apiService.createStorage(name: name)
            context.insert(remoteStorage)
            try context.save()
            return remoteStorage
        } catch {
            print("Failed to create storage: \(error.localizedDescription)")
            throw error
        }
    }

    func addProductAndSync(name: String, category: String, expirationDaysDelta: Int, in context: ModelContext) async throws -> Product {
        do {
            let remoteProduct = try await apiService.createProduct(
                name: name,
                category: category,
                expirationDaysDelta: expirationDaysDelta
            )
            context.insert(remoteProduct)
            try context.save()
            return remoteProduct
        } catch {
            print("Failed to create product: \(error.localizedDescription)")
            throw error
        }
    }

    func addStorageItemAndSync(
        to storage: Storage,
        product: Product,
        expiresAt: Date?,
        in context: ModelContext
    ) async throws -> StorageItem {
        guard let storageId = storage.serverId else {
            throw APIError.invalidURL
        }
        guard let productId = product.serverId else {
            throw APIError.invalidURL
        }
        do {
            let remoteItem = try await apiService.addStorageItem(
                storageId: storageId,
                productId: productId,
                expiresAt: expiresAt
            )
            storage.items.append(remoteItem)
            try context.save()
            return remoteItem
        } catch {
            print("Failed to add storage item: \(error.localizedDescription)")
            throw error
        }
    }

    func addShoppingItemAndSync(
        to storage: Storage,
        product: Product,
        amountToBuy: Int,
        in context: ModelContext
    ) async throws -> ShoppingListItem {
        guard let storageId = storage.serverId else {
            throw APIError.invalidURL
        }
        guard let productId = product.serverId else {
            throw APIError.invalidURL
        }
        do {
            let remoteItem = try await apiService.addShoppingItem(
                storageId: storageId,
                productId: productId,
                amountToBuy: amountToBuy
            )
            storage.shoppingItems.append(remoteItem)
            try context.save()
            return remoteItem
        } catch {
            print("Failed to add shopping item: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Delete Operations

    func deleteStorageAndSync(_ storage: Storage, in context: ModelContext) async throws {
        guard let storageId = storage.serverId else {
            // No serverId means it was never synced — just delete locally
            context.delete(storage)
            try context.save()
            return
        }
        do {
            try await apiService.deleteStorage(id: storageId)
            context.delete(storage)
            try context.save()
        } catch {
            print("Failed to delete storage: \(error.localizedDescription)")
            throw error
        }
    }

    func deleteStorageItemAndSync(_ item: StorageItem, from storage: Storage, in context: ModelContext) async throws {
        guard let storageId = storage.serverId, let itemId = item.serverId else {
            // No serverId means it was never synced — just delete locally
            storage.items.removeAll { $0.id == item.id }
            try context.save()
            return
        }
        do {
            try await apiService.deleteStorageItem(storageId: storageId, itemId: itemId)
            storage.items.removeAll { $0.id == item.id }
            try context.save()
        } catch {
            print("Failed to delete storage item: \(error.localizedDescription)")
            throw error
        }
    }

    func deleteShoppingItemAndSync(_ item: ShoppingListItem, from storage: Storage, in context: ModelContext) async throws {
        guard let storageId = storage.serverId, let itemId = item.serverId else {
            storage.shoppingItems.removeAll { $0.id == item.id }
            try context.save()
            return
        }
        do {
            try await apiService.deleteShoppingItem(storageId: storageId, itemId: itemId)
            storage.shoppingItems.removeAll { $0.id == item.id }
            try context.save()
        } catch {
            print("Failed to delete shopping item: \(error.localizedDescription)")
            throw error
        }
    }
}
