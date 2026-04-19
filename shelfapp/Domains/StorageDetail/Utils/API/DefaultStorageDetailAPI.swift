import Foundation

struct DefaultStorageDetailAPI: StorageDetailAPI {
    private let http: StorageDetailHTTPClient

    init(http: StorageDetailHTTPClient) {
        self.http = http
    }

    init() {
        self.init(http: DefaultStorageDetailHTTPClient())
    }

    func fetchStorage(id: Int) async throws -> Storage {
        let dto: StorageDTO = try await http.request(.storage(.init(id: id)))
        return dto.toDomain()
    }

    func fetchStorageItems(storageId: Int) async throws -> [StorageItem] {
        let dtos: [StorageItemDTO] = try await http.request(.storageItems(.init(storageId: storageId)))
        return dtos.map { $0.toDomain() }
    }

    func fetchShoppingItems(storageId: Int) async throws -> [ShoppingListItem] {
        let dtos: [ShoppingListItemDTO] = try await http.request(.shoppingList(.init(storageId: storageId)))
        return dtos.map { $0.toDomain() }
    }

    func fetchRunningLowSettings(storageId: Int) async throws -> [RunningLowSetting] {
        let dtos: [RunningLowSettingDTO] = try await http.request(.runningLowSettings(.init(storageId: storageId)))
        return dtos.map { $0.toDomain() }
    }

    func fetchMembers(storageId: Int) async throws -> [StorageMemberInfo] {
        let dtos: [StorageMemberDTO] = try await http.request(.storageMembers(.init(storageId: storageId)))
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
            .addStorageItem(.init(storageId: storageId, body: StorageDetailRequestBody.AddStorageItem(productId: productId, expiresAt: formattedDate)))
        )
        return dto.toDomain()
    }

    func removeMember(storageId: Int, userId: Int) async throws {
        let _: EmptyResponse = try await http.request(.removeStorageMember(.init(storageId: storageId, userId: userId)))
    }

    func inviteMember(storageId: Int, email: String) async throws -> StorageMemberInfo {
        let dto: StorageMemberDTO = try await http.request(.inviteStorageMember(.init(storageId: storageId, body: StorageDetailRequestBody.InviteMember(email: email))))
        return StorageMemberInfo(id: dto.id, userId: dto.user.id, username: dto.user.username, accepted: dto.accepted)
    }

    func deleteStorageItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteStorageItem(.init(storageId: storageId, itemId: itemId)))
    }

    func deleteShoppingItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteShoppingItem(.init(storageId: storageId, itemId: itemId)))
    }

    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem {
        let dto: ShoppingListItemDTO = try await http.request(
            .addShoppingItem(.init(storageId: storageId, body: StorageDetailRequestBody.AddShoppingItem(productId: productId, amountToBuy: amountToBuy)))
        )
        return dto.toDomain()
    }

    func updateShoppingItemAmount(storageId: Int, itemId: Int, amountToBuy: Int) async throws -> ShoppingListItem {
        let dto: ShoppingListItemDTO = try await http.request(
            .updateShoppingItem(.init(storageId: storageId, itemId: itemId, body: StorageDetailRequestBody.UpdateShoppingItem(amountToBuy: amountToBuy)))
        )
        return dto.toDomain()
    }

    func completeShoppingItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.completeShoppingItem(.init(storageId: storageId, itemId: itemId)))
    }

    func createRunningLowSetting(storageId: Int, productId: Int, threshold: Int) async throws -> RunningLowSetting {
        let dto: RunningLowSettingDTO = try await http.request(
            .createRunningLowSetting(.init(storageId: storageId, body: StorageDetailRequestBody.CreateRunningLow(productId: productId, runningLow: threshold)))
        )
        return dto.toDomain()
    }

    func updateRunningLowSetting(storageId: Int, settingId: Int, threshold: Int) async throws -> RunningLowSetting {
        let dto: RunningLowSettingDTO = try await http.request(
            .updateRunningLowSetting(.init(storageId: storageId, settingId: settingId, body: StorageDetailRequestBody.UpdateRunningLow(runningLow: threshold)))
        )
        return dto.toDomain()
    }

    func deleteRunningLowSetting(storageId: Int, settingId: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteRunningLowSetting(.init(storageId: storageId, settingId: settingId)))
    }
}
