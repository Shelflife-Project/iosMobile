import Foundation

struct DefaultShoppingListAPI: ShoppingListAPI {
    private let http: ShoppingListHTTPClient

    init(http: ShoppingListHTTPClient) {
        self.http = http
    }

    init() {
        self.init(http: DefaultShoppingListHTTPClient())
    }

    func fetchShoppingItems(storageId: Int) async throws -> [ShoppingListItem] {
        let dtos: [ShoppingListItemDTO] = try await http.request(.shoppingList(.init(storageId: storageId)))
        return dtos.map { $0.toDomain() }
    }

    func fetchAggregatedShoppingItems() async throws -> [ShoppingListItem] {
        let dtos: [ShoppingListItemDTO] = try await http.request(.shoppingListAggregated)
        return dtos.map { $0.toDomain() }
    }

    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem {
        let dto: ShoppingListItemDTO = try await http.request(
            .addShoppingItem(.init(storageId: storageId, body: ShoppingListRequestBody.AddItem(productId: productId, amountToBuy: amountToBuy)))
        )
        return dto.toDomain()
    }

    func updateShoppingItemAmount(storageId: Int, itemId: Int, amountToBuy: Int) async throws -> ShoppingListItem {
        let dto: ShoppingListItemDTO = try await http.request(
            .updateShoppingItem(.init(storageId: storageId, itemId: itemId, body: ShoppingListRequestBody.UpdateItem(amountToBuy: amountToBuy)))
        )
        return dto.toDomain()
    }

    func deleteShoppingItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteShoppingItem(.init(storageId: storageId, itemId: itemId)))
    }

    func completeShoppingItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.completeShoppingItem(.init(storageId: storageId, itemId: itemId)))
    }

    func addStorageItem(storageId: Int, productId: Int, expiresAt: Date?) async throws -> StorageItem {
        let formattedDate = expiresAt.map { date in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.string(from: date)
        }

        let dto: StorageItemDTO = try await http.request(
            .addStorageItem(.init(storageId: storageId, body: ShoppingListRequestBody.AddStorageItem(productId: productId, expiresAt: formattedDate)))
        )
        return dto.toDomain()
    }
}
