import Foundation

struct DefaultStorageDetailAPI: StorageDetailAPI {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    init() {
        self.init(http: DefaultHTTPClient())
    }

    func fetchStorage(id: Int) async throws -> Storage {
        let dto: StorageDTO = try await http.request(.storage(id: id))
        return dto.toDomain()
    }

    func fetchStorageItems(storageId: Int) async throws -> [StorageItem] {
        let dtos: [StorageItemDTO] = try await http.request(.storageItems(storageId: storageId))
        return dtos.map { $0.toDomain() }
    }

    func fetchShoppingItems(storageId: Int) async throws -> [ShoppingListItem] {
        let dtos: [ShoppingListItemDTO] = try await http.request(.shoppingList(storageId: storageId))
        return dtos.map { $0.toDomain() }
    }

    func fetchRunningLowSettings(storageId: Int) async throws -> [RunningLowSetting] {
        let dtos: [RunningLowSettingDTO] = try await http.request(.runningLowSettings(storageId: storageId))
        return dtos.map { $0.toDomain() }
    }

    func fetchMembers(storageId: Int) async throws -> [StorageMemberInfo] {
        let dtos: [StorageMemberDTO] = try await http.request(.storageMembers(storageId: storageId))
        return dtos.map {
            StorageMemberInfo(id: $0.id, userId: $0.user.id, username: $0.user.username, accepted: $0.accepted)
        }
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

    func removeMember(storageId: Int, userId: Int) async throws {
        let _: EmptyResponse = try await http.request(.removeStorageMember(storageId: storageId, userId: userId))
    }

    func inviteMember(storageId: Int, email: String) async throws -> StorageMemberInfo {
        let dto: StorageMemberDTO = try await http.request(.inviteStorageMember(storageId: storageId, body: InviteMemberBody(email: email)))
        return StorageMemberInfo(id: dto.id, userId: dto.user.id, username: dto.user.username, accepted: dto.accepted)
    }

    func deleteStorageItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteStorageItem(storageId: storageId, itemId: itemId))
    }

    func deleteShoppingItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteShoppingItem(storageId: storageId, itemId: itemId))
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

    func completeShoppingItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.completeShoppingItem(storageId: storageId, itemId: itemId))
    }

    func createRunningLowSetting(storageId: Int, productId: Int, threshold: Int) async throws -> RunningLowSetting {
        let dto: RunningLowSettingDTO = try await http.request(
            .createRunningLowSetting(storageId: storageId, body: RunningLowCreateBody(productId: productId, runningLow: threshold))
        )
        return dto.toDomain()
    }

    func updateRunningLowSetting(storageId: Int, settingId: Int, threshold: Int) async throws -> RunningLowSetting {
        let dto: RunningLowSettingDTO = try await http.request(
            .updateRunningLowSetting(storageId: storageId, settingId: settingId, body: RunningLowUpdateBody(runningLow: threshold))
        )
        return dto.toDomain()
    }

    func deleteRunningLowSetting(storageId: Int, settingId: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteRunningLowSetting(storageId: storageId, settingId: settingId))
    }
}
