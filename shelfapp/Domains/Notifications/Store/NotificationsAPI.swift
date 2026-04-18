import Foundation

protocol NotificationsAPI {
    func fetchPendingInvites() async throws -> [PendingInviteInfo]
    func fetchAggregatedRunningLowNotifications() async throws -> [RunningLowNotification]
    func fetchAggregatedAboutToExpireItems() async throws -> [StorageItem]
    func acceptInvite(inviteId: Int) async throws
    func declineInvite(inviteId: Int) async throws
    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem
    func deleteStorageItem(storageId: Int, itemId: Int) async throws
}

struct DefaultNotificationsAPI: NotificationsAPI {
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    init() {
        self.init(http: DefaultHTTPClient())
    }

    func fetchPendingInvites() async throws -> [PendingInviteInfo] {
        let dtos: [StorageMemberDTO] = try await http.request(.storageInvites)
        return dtos.map {
            PendingInviteInfo(
                id: $0.id,
                storageName: $0.storage?.name ?? "Unknown",
                storageId: $0.storage?.id ?? 0,
                invitedBy: $0.storage?.owner?.username ?? "Unknown"
            )
        }
    }

    func fetchAggregatedRunningLowNotifications() async throws -> [RunningLowNotification] {
        do {
            let groupedDTOs: [RunningLowNotificationDTO] = try await http.request(.runningLowAggregated)
            return groupedDTOs.map {
                RunningLowNotification(
                    storageId: $0.storageId,
                    storageName: $0.storageName,
                    items: $0.items.map { RunningLowNotification.Item(id: $0.id, productName: $0.productName, quantity: $0.quantity) }
                )
            }
        } catch {
            let legacyDTOs: [RunningLowLegacyDTO] = try await http.request(.runningLowAggregated)
            let grouped = Dictionary(grouping: legacyDTOs, by: { $0.storage.id })

            return grouped.compactMap { storageId, items in
                guard let first = items.first else { return nil }
                return RunningLowNotification(
                    storageId: storageId,
                    storageName: first.storage.name,
                    items: items.map {
                        RunningLowNotification.Item(
                            id: $0.product.id,
                            productName: $0.product.name,
                            quantity: $0.amount
                        )
                    }
                )
            }
            .sorted { $0.storageName.localizedCaseInsensitiveCompare($1.storageName) == .orderedAscending }
        }
    }

    func fetchAggregatedAboutToExpireItems() async throws -> [StorageItem] {
        do {
            let dtos: [AboutToExpireItemDTO] = try await http.request(.aboutToExpire)
            return dtos.map { $0.toDomain() }
        } catch APIError.notFound {
            let dtos: [AboutToExpireItemDTO] = try await http.request(.aboutToExpireLegacy)
            return dtos.map { $0.toDomain() }
        }
    }

    func acceptInvite(inviteId: Int) async throws {
        let _: EmptyResponse = try await http.request(.acceptInvite(inviteId: inviteId))
    }

    func declineInvite(inviteId: Int) async throws {
        let _: EmptyResponse = try await http.request(.declineInvite(inviteId: inviteId))
    }

    func addShoppingItem(storageId: Int, productId: Int, amountToBuy: Int) async throws -> ShoppingListItem {
        let dto: ShoppingListItemDTO = try await http.request(
            .addShoppingItem(storageId: storageId, body: ShoppingItemCreateBody(productId: productId, amountToBuy: amountToBuy))
        )
        return dto.toDomain()
    }

    func deleteStorageItem(storageId: Int, itemId: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteStorageItem(storageId: storageId, itemId: itemId))
    }
}
