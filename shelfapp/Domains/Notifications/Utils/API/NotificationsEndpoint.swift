import Foundation

enum NotificationsEndpoint: HTTPEndpoint {
    case storageInvites
    case runningLowAggregated
    case aboutToExpire
    case aboutToExpireLegacy
    case acceptInvite(NotificationsRequestDTO.InviteId)
    case declineInvite(NotificationsRequestDTO.InviteId)
    case addShoppingItem(NotificationsRequestDTO.AddShoppingItem)
    case deleteStorageItem(NotificationsRequestDTO.StorageItemScope)

    var path: String {
        switch self {
        case .storageInvites: return "/api/storages/invites"
        case .runningLowAggregated: return "/api/runninglow"
        case .aboutToExpire: return "/api/abouttoexpire"
        case .aboutToExpireLegacy: return "/api/storages/items/expiring"
        case .acceptInvite(let request): return "/api/storages/invites/\(request.inviteId)"
        case .declineInvite(let request): return "/api/storages/invites/\(request.inviteId)"
        case .addShoppingItem(let request): return "/api/storages/\(request.storageId)/shoppinglist"
        case .deleteStorageItem(let request): return "/api/storages/\(request.storageId)/items/\(request.itemId)"
        }
    }

    var method: String {
        switch self {
        case .acceptInvite, .addShoppingItem:
            return "POST"
        case .declineInvite, .deleteStorageItem:
            return "DELETE"
        case .storageInvites, .runningLowAggregated, .aboutToExpire, .aboutToExpireLegacy:
            return "GET"
        }
    }

    var body: AnyEncodable? {
        switch self {
        case .addShoppingItem(let request):
            return AnyEncodable(request.body)
        default:
            return nil
        }
    }

    var contentType: String? {
        switch self {
        case .addShoppingItem:
            return "application/json"
        default:
            return nil
        }
    }
}
