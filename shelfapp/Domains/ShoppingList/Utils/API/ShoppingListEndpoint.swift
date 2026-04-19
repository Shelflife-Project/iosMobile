import Foundation

enum ShoppingListEndpoint: HTTPEndpoint {
    case shoppingListAggregated
    case shoppingList(ShoppingListRequestDTO.StorageScope)
    case addShoppingItem(ShoppingListRequestDTO.AddShoppingItem)
    case updateShoppingItem(ShoppingListRequestDTO.UpdateShoppingItem)
    case deleteShoppingItem(ShoppingListRequestDTO.ShoppingItemScope)
    case completeShoppingItem(ShoppingListRequestDTO.ShoppingItemScope)
    case addStorageItem(ShoppingListRequestDTO.AddStorageItem)

    var path: String {
        switch self {
        case .shoppingListAggregated: return "/api/shoppinglist"
        case .shoppingList(let request): return "/api/storages/\(request.storageId)/shoppinglist"
        case .addShoppingItem(let request): return "/api/storages/\(request.storageId)/shoppinglist"
        case .updateShoppingItem(let request): return "/api/storages/\(request.storageId)/shoppinglist/\(request.itemId)"
        case .deleteShoppingItem(let request): return "/api/storages/\(request.storageId)/shoppinglist/\(request.itemId)"
        case .completeShoppingItem(let request): return "/api/storages/\(request.storageId)/shoppinglist/\(request.itemId)"
        case .addStorageItem(let request): return "/api/storages/\(request.storageId)/items"
        }
    }

    var method: String {
        switch self {
        case .addShoppingItem, .completeShoppingItem, .addStorageItem:
            return "POST"
        case .updateShoppingItem:
            return "PUT"
        case .deleteShoppingItem:
            return "DELETE"
        case .shoppingListAggregated, .shoppingList:
            return "GET"
        }
    }

    var body: AnyEncodable? {
        switch self {
        case .addShoppingItem(let request): return AnyEncodable(request.body)
        case .updateShoppingItem(let request): return AnyEncodable(request.body)
        case .addStorageItem(let request): return AnyEncodable(request.body)
        default: return nil
        }
    }

    var contentType: String? {
        switch self {
        case .addShoppingItem, .updateShoppingItem, .addStorageItem:
            return "application/json"
        default:
            return nil
        }
    }
}
