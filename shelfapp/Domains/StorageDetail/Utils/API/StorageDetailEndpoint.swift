import Foundation

enum StorageDetailEndpoint: HTTPEndpoint {
    case storage(StorageDetailRequestDTO.StorageId)
    case storageItems(StorageDetailRequestDTO.StorageScope)
    case addStorageItem(StorageDetailRequestDTO.AddStorageItem)
    case deleteStorageItem(StorageDetailRequestDTO.StorageItemScope)

    case shoppingList(StorageDetailRequestDTO.StorageScope)
    case addShoppingItem(StorageDetailRequestDTO.AddShoppingItem)
    case updateShoppingItem(StorageDetailRequestDTO.UpdateShoppingItem)
    case deleteShoppingItem(StorageDetailRequestDTO.ShoppingItemScope)
    case completeShoppingItem(StorageDetailRequestDTO.ShoppingItemScope)

    case storageMembers(StorageDetailRequestDTO.StorageScope)
    case inviteStorageMember(StorageDetailRequestDTO.InviteMember)
    case removeStorageMember(StorageDetailRequestDTO.MemberScope)

    case runningLowSettings(StorageDetailRequestDTO.RunningLowScope)
    case createRunningLowSetting(StorageDetailRequestDTO.CreateRunningLow)
    case updateRunningLowSetting(StorageDetailRequestDTO.UpdateRunningLow)
    case deleteRunningLowSetting(StorageDetailRequestDTO.DeleteRunningLow)

    var path: String {
        switch self {
        case .storage(let request): return "/api/storages/\(request.id)"
        case .storageItems(let request): return "/api/storages/\(request.storageId)/items"
        case .addStorageItem(let request): return "/api/storages/\(request.storageId)/items"
        case .deleteStorageItem(let request): return "/api/storages/\(request.storageId)/items/\(request.itemId)"

        case .shoppingList(let request): return "/api/storages/\(request.storageId)/shoppinglist"
        case .addShoppingItem(let request): return "/api/storages/\(request.storageId)/shoppinglist"
        case .updateShoppingItem(let request): return "/api/storages/\(request.storageId)/shoppinglist/\(request.itemId)"
        case .deleteShoppingItem(let request): return "/api/storages/\(request.storageId)/shoppinglist/\(request.itemId)"
        case .completeShoppingItem(let request): return "/api/storages/\(request.storageId)/shoppinglist/\(request.itemId)"

        case .storageMembers(let request): return "/api/storages/\(request.storageId)/members"
        case .inviteStorageMember(let request): return "/api/storages/\(request.storageId)/members"
        case .removeStorageMember(let request): return "/api/storages/\(request.storageId)/members/\(request.userId)"

        case .runningLowSettings(let request): return "/api/storages/\(request.storageId)/runninglowsettings"
        case .createRunningLowSetting(let request): return "/api/storages/\(request.storageId)/runninglowsettings"
        case .updateRunningLowSetting(let request): return "/api/storages/\(request.storageId)/runninglowsettings/\(request.settingId)"
        case .deleteRunningLowSetting(let request): return "/api/storages/\(request.storageId)/runninglowsettings/\(request.settingId)"
        }
    }

    var method: String {
        switch self {
        case .addStorageItem, .addShoppingItem, .completeShoppingItem, .inviteStorageMember, .createRunningLowSetting:
            return "POST"
        case .updateShoppingItem, .updateRunningLowSetting:
            return "PUT"
        case .deleteStorageItem, .deleteShoppingItem, .removeStorageMember, .deleteRunningLowSetting:
            return "DELETE"
        case .storage, .storageItems, .shoppingList, .storageMembers, .runningLowSettings:
            return "GET"
        }
    }

    var body: AnyEncodable? {
        switch self {
        case .addStorageItem(let request): return AnyEncodable(request.body)
        case .addShoppingItem(let request): return AnyEncodable(request.body)
        case .updateShoppingItem(let request): return AnyEncodable(request.body)
        case .inviteStorageMember(let request): return AnyEncodable(request.body)
        case .createRunningLowSetting(let request): return AnyEncodable(request.body)
        case .updateRunningLowSetting(let request): return AnyEncodable(request.body)
        default: return nil
        }
    }

    var contentType: String? {
        switch self {
        case .addStorageItem, .addShoppingItem, .updateShoppingItem, .inviteStorageMember,
                .createRunningLowSetting, .updateRunningLowSetting:
            return "application/json"
        default:
            return nil
        }
    }
}
