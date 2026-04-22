import Foundation

enum PushNotificationDecoder {
    static func decode(_ userInfo: [AnyHashable: Any]) -> NavigationIntent? {
        guard let intent = userInfo["intent"] as? String else { return nil }
        switch intent {
        case "running_low":
            guard let storageId = userInfo["storageId"] as? Int,
                  let productId = userInfo["productId"] as? Int else { return nil }
            return .runningLowAlert(storageId: storageId, productId: productId)
        case "shopping_item_added":
            guard let storageId = userInfo["storageId"] as? Int else { return nil }
            return .shoppingListItemAdded(storageId: storageId)
        case "invite", "open_storage":
            guard let storageId = userInfo["storageId"] as? Int else { return nil }
            return .openStorage(id: storageId)
        default:
            return nil
        }
    }
}
