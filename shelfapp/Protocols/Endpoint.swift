import Foundation

struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: some Encodable) {
        self.encodeClosure = { encoder in
            try wrapped.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

struct LoginBody: Encodable {
    let email: String
    let password: String
}

struct SignupBody: Encodable {
    let username: String
    let email: String
    let password: String
    let passwordRepeat: String
}

struct ChangePasswordBody: Encodable {
    let oldPassword: String
    let newPassword: String
    let newPasswordRepeat: String
}

struct ProductUpsertBody: Encodable {
    let name: String
    let category: String
    let expirationDaysDelta: Int
    let barcode: String?
}

struct StorageUpsertBody: Encodable {
    let name: String
}

struct UserUpdateBody: Encodable {
    let username: String?
    let email: String?
}

struct ShoppingItemCreateBody: Encodable {
    let productId: Int
    let amountToBuy: Int
}

struct ShoppingItemUpdateBody: Encodable {
    let amountToBuy: Int
}

struct StorageItemCreateBody: Encodable {
    let productId: Int
    let expiresAt: String?
}

struct InviteMemberBody: Encodable {
    let email: String
}

struct RunningLowCreateBody: Encodable {
    let productId: Int
    let runningLow: Int
}

struct RunningLowUpdateBody: Encodable {
    let runningLow: Int
}

enum Endpoint {
    case login(LoginBody)
    case signup(SignupBody)
    case changePassword(ChangePasswordBody)
    case me
    case logout

    case products(search: String, page: Int, size: Int)
    case categories
    case createProduct(ProductUpsertBody)
    case updateProduct(id: Int, body: ProductUpsertBody)
    case deleteProduct(id: Int)

    case storages(search: String, page: Int, size: Int)
    case storage(id: Int)
    case createStorage(StorageUpsertBody)
    case updateStorage(id: Int, body: StorageUpsertBody)
    case deleteStorage(id: Int)

    case updateUser(id: Int, body: UserUpdateBody)
    case uploadUserProfilePicture(userId: Int, imageData: Data)

    case shoppingListAggregated
    case shoppingList(storageId: Int)
    case addShoppingItem(storageId: Int, body: ShoppingItemCreateBody)
    case updateShoppingItem(storageId: Int, itemId: Int, body: ShoppingItemUpdateBody)
    case deleteShoppingItem(storageId: Int, itemId: Int)
    case completeShoppingItem(storageId: Int, itemId: Int)

    case storageItems(storageId: Int)
    case addStorageItem(storageId: Int, body: StorageItemCreateBody)
    case deleteStorageItem(storageId: Int, itemId: Int)

    case storageMembers(storageId: Int)
    case inviteStorageMember(storageId: Int, body: InviteMemberBody)
    case removeStorageMember(storageId: Int, userId: Int)

    case storageInvites
    case acceptInvite(inviteId: Int)
    case declineInvite(inviteId: Int)

    case runningLowAggregated
    case aboutToExpire
    case aboutToExpireLegacy

    case runningLowSettings(storageId: Int)
    case createRunningLowSetting(storageId: Int, body: RunningLowCreateBody)
    case updateRunningLowSetting(storageId: Int, settingId: Int, body: RunningLowUpdateBody)
    case deleteRunningLowSetting(storageId: Int, settingId: Int)

    private static let profileUploadBoundary = "ShelfLifeProfileUploadBoundary"

    private static func profileUploadBody(imageData: Data) -> Data {
        var body = Data()
        let boundary = profileUploadBoundary
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"pfp\"; filename=\"pfp.jpg\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(imageData)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        return body
    }

    var path: String {
        switch self {
        case .login(_): return "/api/auth/login"
        case .signup(_): return "/api/auth/signup"
        case .changePassword(_): return "/api/auth/password/change"
        case .me: return "/api/auth/me"
        case .logout: return "/api/auth/logout"
        case .products(_, _, _): return "/api/products"
        case .categories: return "/api/products/categories"
        case .createProduct(_): return "/api/products"
        case .updateProduct(let id, _): return "/api/products/\(id)"
        case .deleteProduct(let id): return "/api/products/\(id)"
        case .storages(_, _, _): return "/api/storages"
        case .storage(let id): return "/api/storages/\(id)"
        case .createStorage(_): return "/api/storages"
        case .updateStorage(let id, _): return "/api/storages/\(id)"
        case .deleteStorage(let id): return "/api/storages/\(id)"
        case .updateUser(let id, _): return "/api/users/\(id)"
        case .uploadUserProfilePicture(let userId, _): return "/api/users/\(userId)/pfp"
        case .shoppingListAggregated: return "/api/shoppinglist"
        case .shoppingList(let storageId): return "/api/storages/\(storageId)/shoppinglist"
        case .addShoppingItem(let storageId, _): return "/api/storages/\(storageId)/shoppinglist"
        case .updateShoppingItem(let storageId, let itemId, _): return "/api/storages/\(storageId)/shoppinglist/\(itemId)"
        case .deleteShoppingItem(let storageId, let itemId): return "/api/storages/\(storageId)/shoppinglist/\(itemId)"
        case .completeShoppingItem(let storageId, let itemId): return "/api/storages/\(storageId)/shoppinglist/\(itemId)"
        case .storageItems(let storageId): return "/api/storages/\(storageId)/items"
        case .addStorageItem(let storageId, _): return "/api/storages/\(storageId)/items"
        case .deleteStorageItem(let storageId, let itemId): return "/api/storages/\(storageId)/items/\(itemId)"
        case .storageMembers(let storageId): return "/api/storages/\(storageId)/members"
        case .inviteStorageMember(let storageId, _): return "/api/storages/\(storageId)/members"
        case .removeStorageMember(let storageId, let userId): return "/api/storages/\(storageId)/members/\(userId)"
        case .storageInvites: return "/api/storages/invites"
        case .acceptInvite(let inviteId): return "/api/storages/invites/\(inviteId)"
        case .declineInvite(let inviteId): return "/api/storages/invites/\(inviteId)"
        case .runningLowAggregated: return "/api/runninglow"
        case .aboutToExpire: return "/api/abouttoexpire"
        case .aboutToExpireLegacy: return "/api/storages/items/expiring"
        case .runningLowSettings(let storageId): return "/api/storages/\(storageId)/runninglowsettings"
        case .createRunningLowSetting(let storageId, _): return "/api/storages/\(storageId)/runninglowsettings"
        case .updateRunningLowSetting(let storageId, let settingId, _): return "/api/storages/\(storageId)/runninglowsettings/\(settingId)"
        case .deleteRunningLowSetting(let storageId, let settingId): return "/api/storages/\(storageId)/runninglowsettings/\(settingId)"
        }
    }

    var method: String {
        switch self {
        case .login(_), .signup(_), .changePassword(_), .createProduct(_), .createStorage(_), .logout,
                .addShoppingItem(_, _), .completeShoppingItem(_, _), .addStorageItem(_, _),
                .inviteStorageMember(_, _), .acceptInvite(_), .createRunningLowSetting(_, _),
                .uploadUserProfilePicture(_, _):
            return "POST"
        case .updateProduct(_, _), .updateStorage(_, _), .updateUser(_, _):
            return "PATCH"
        case .updateShoppingItem(_, _, _), .updateRunningLowSetting(_, _, _):
            return "PUT"
        case .deleteProduct(_), .deleteStorage(_), .deleteShoppingItem(_, _), .deleteStorageItem(_, _), .removeStorageMember(_, _),
                .declineInvite(_), .deleteRunningLowSetting(_, _):
            return "DELETE"
        case .me, .products(_, _, _), .categories, .storage(_), .storages(_, _, _), .shoppingListAggregated,
                .shoppingList(_), .storageItems(_), .storageMembers(_), .storageInvites, .runningLowAggregated,
                .aboutToExpire, .aboutToExpireLegacy, .runningLowSettings(_):
            return "GET"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .products(search, page, size), let .storages(search, page, size):
            var items = [URLQueryItem(name: "search", value: search)]
            if size > 0 {
                items.append(URLQueryItem(name: "page", value: String(page)))
                items.append(URLQueryItem(name: "size", value: String(size)))
            }
            return items
        default:
            return []
        }
    }

    var body: AnyEncodable? {
        switch self {
        case .login(let body): return AnyEncodable(body)
        case .signup(let body): return AnyEncodable(body)
        case .changePassword(let body): return AnyEncodable(body)
        case .createProduct(let body): return AnyEncodable(body)
        case .updateProduct(_, let body): return AnyEncodable(body)
        case .createStorage(let body): return AnyEncodable(body)
        case .updateStorage(_, let body): return AnyEncodable(body)
        case .updateUser(_, let body): return AnyEncodable(body)
        case .addShoppingItem(_, let body): return AnyEncodable(body)
        case .updateShoppingItem(_, _, let body): return AnyEncodable(body)
        case .addStorageItem(_, let body): return AnyEncodable(body)
        case .inviteStorageMember(_, let body): return AnyEncodable(body)
        case .createRunningLowSetting(_, let body): return AnyEncodable(body)
        case .updateRunningLowSetting(_, _, let body): return AnyEncodable(body)
        default: return nil
        }
    }

    var rawBody: Data? {
        switch self {
        case .uploadUserProfilePicture(_, let imageData):
            return Self.profileUploadBody(imageData: imageData)
        default:
            return nil
        }
    }

    var contentType: String? {
        switch self {
        case .login, .signup, .changePassword, .createProduct, .updateProduct, .createStorage, .updateStorage,
                .updateUser, .addShoppingItem, .updateShoppingItem, .addStorageItem, .inviteStorageMember,
                .createRunningLowSetting, .updateRunningLowSetting:
            return "application/json"
        case .uploadUserProfilePicture:
            return "multipart/form-data; boundary=\(Self.profileUploadBoundary)"
        default:
            return nil
        }
    }
}

typealias HttpRequest = Endpoint