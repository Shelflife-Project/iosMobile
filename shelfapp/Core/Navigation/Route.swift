import Foundation

enum HomeRoute: Hashable {
    case storageDetail(id: Int)
}

enum StoragesRoute: Hashable {
    case storageDetail(id: Int)
}

enum ShoppingListRoute: Hashable {}

enum NotificationsRoute: Hashable {}

enum ProfileRoute: Hashable {}

enum SheetRoute: Identifiable {
    case createStorage
    case createProduct
    case inviteMember(storageId: Int)

    var id: String {
        switch self {
        case .createStorage: return "createStorage"
        case .createProduct: return "createProduct"
        case .inviteMember(let id): return "inviteMember_\(id)"
        }
    }
}
