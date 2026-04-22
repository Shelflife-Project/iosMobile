import Foundation

enum NavigationIntent {
    case runningLowAlert(storageId: Int, productId: Int)
    case shoppingListItemAdded(storageId: Int)
    case openStorage(id: Int)
    case openNotifications
    case openShoppingList
}
