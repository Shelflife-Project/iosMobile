import Foundation

protocol ShoppingListAPI {
    func fetchShoppingItems(storageId: Int) async throws -> [ShoppingListItem]
    func fetchAggregatedShoppingItems() async throws -> [ShoppingListItem]
    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem
    func updateShoppingItemAmount(storageId: Int, itemId: Int, amountToBuy: Int) async throws -> ShoppingListItem
    func deleteShoppingItem(storageId: Int, itemId: Int) async throws
    func completeShoppingItem(storageId: Int, itemId: Int) async throws
    func addStorageItem(storageId: Int, productId: Int, expiresAt: Date?) async throws -> StorageItem
}

struct DefaultShoppingListAPI: ShoppingListAPI {
    private let http: HTTPClient

    init(http: HTTPClient = DefaultHTTPClient()) {
        self.http = http
    }

    func fetchShoppingItems(storageId: Int) async throws -> [ShoppingListItem] {
        let dtos: [ShoppingListItemDTO] = try await http.request(.shoppingList(storageId: storageId))
        return dtos.map { $0.toDomain() }
    }

    func fetchAggregatedShoppingItems() async throws -> [ShoppingListItem] {
        let dtos: [ShoppingListItemDTO] = try await http.request(.shoppingListAggregated)
        return dtos.map { $0.toDomain() }
    }

    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem {
        let dto: ShoppingListItemDTO = try await http.request(
            .addShoppingItem(storageId: storageId, body: ShoppingItemCreateBody(productId: productId, amountToBuy: amountToBuy))
        )
        return dto.toDomain()
    }

    func updateShoppingItemAmount(storageId: Int, itemId: Int, amountToBuy: Int) async throws -> ShoppingListItem {
        let dto: ShoppingListItemDTO = try await http.request(
            .updateShoppingItem(storageId: storageId, itemId: itemId, body: ShoppingItemUpdateBody(amountToBuy: amountToBuy))
        )
        return dto.toDomain()
    }

    func deleteShoppingItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteShoppingItem(storageId: storageId, itemId: itemId))
    }

    func completeShoppingItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.completeShoppingItem(storageId: storageId, itemId: itemId))
    }

    func addStorageItem(storageId: Int, productId: Int, expiresAt: Date?) async throws -> StorageItem {
        let formattedDate = expiresAt.map { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.string(from: date)
        }

        let dto: StorageItemDTO = try await http.request(
            .addStorageItem(storageId: storageId, body: StorageItemCreateBody(productId: productId, expiresAt: formattedDate))
        )
        return dto.toDomain()
    }
}
