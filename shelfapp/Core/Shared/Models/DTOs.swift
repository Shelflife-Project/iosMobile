import Foundation

// MARK: - Shared Helper Types

struct PendingInviteInfo: Identifiable {
    let id: Int
    let storageName: String
    let storageId: Int
    let invitedBy: String
}

struct RunningLowNotification: Identifiable, Hashable {
    struct Item: Identifiable, Hashable {
        let id: Int
        let productName: String
        let quantity: Int
    }

    let storageId: Int
    let storageName: String
    let items: [Item]
    
    var id: Int { storageId }
}

struct StorageMemberInfo: Identifiable {
    let id: Int
    let userId: Int
    let username: String
    let accepted: Bool
}

// MARK: - Shared Response Models

struct PaginatedResponseDTO<T: Codable>: Codable {
    let data: [T]
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let pageSize: Int
    let hasNext: Bool
    let hasPrevious: Bool
}

// MARK: - Auth DTOs

struct LoginRequestDTO: Codable {
    let email: String
    let password: String
}

struct SignUpRequestDTO: Codable {
    let email: String
    let username: String
    let password: String
    let passwordRepeat: String
}

struct ChangePasswordRequestDTO: Codable {
    let oldPassword: String
    let newPassword: String
    let newPasswordRepeat: String
}

struct ChangeUserDataRequestDTO: Codable {
    let email: String?
    let username: String?
    let isAdmin: Bool?
}

struct AuthResponseDTO: Codable {
    let token: String
}

// MARK: - User Model

struct UserDTO: Codable {
    let id: Int
    let email: String?
    let username: String
    let isAdmin: Bool

    var admin: Bool { isAdmin }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case isAdmin
        case admin
    }

    init(id: Int, email: String? = nil, username: String, admin: Bool = false) {
        self.id = id
        self.email = email
        self.username = username
        self.isAdmin = admin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin)
            ?? container.decodeIfPresent(Bool.self, forKey: .admin)
            ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(username, forKey: .username)
        try container.encode(isAdmin, forKey: .admin)
    }
    
    func toDomain() -> User {
        User(from: self)
    }
}

// MARK: - Product DTOs

struct CreateProductRequestDTO: Codable {
    let name: String
    let description: String?
    let category: String
    let barcode: String?
    let expirationDaysDelta: Int
}

struct UpdateProductRequestDTO: Codable {
    let name: String?
    let description: String?
    let category: String?
    let barcode: String?
    let expirationDaysDelta: Int?
}

struct ProductDTO: Codable {
    let id: Int
    let ownerId: Int?
    let name: String
    let description: String?
    let category: String
    let barcode: String?
    let expirationDaysDelta: Int

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId
        case owner
        case name
        case description
        case category
        case barcode
        case expirationDaysDelta
    }

    init(id: Int, ownerId: Int? = nil, name: String, category: String, expirationDaysDelta: Int, barcode: String?, description: String? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.description = description
        self.category = category
        self.barcode = barcode
        self.expirationDaysDelta = expirationDaysDelta
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        ownerId = try container.decodeIfPresent(Int.self, forKey: .ownerId)
            ?? container.decodeIfPresent(UserDTO.self, forKey: .owner)?.id
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decode(String.self, forKey: .category)
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
        expirationDaysDelta = try container.decode(Int.self, forKey: .expirationDaysDelta)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(ownerId, forKey: .ownerId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(barcode, forKey: .barcode)
        try container.encode(expirationDaysDelta, forKey: .expirationDaysDelta)
    }
    
    func toDomain() -> Product {
        Product(from: self)
    }
}

// MARK: - Storage DTOs

struct CreateStorageRequestDTO: Codable {
    let name: String
}

struct ChangeStorageNameRequestDTO: Codable {
    let name: String
}

struct StorageDTO: Codable {
    let id: Int
    let owner: UserDTO?
    let name: String
    let items: [StorageItemDTO]?
    let members: [StorageMemberDTO]?

    init(id: Int, name: String, owner: UserDTO?, items: [StorageItemDTO]? = nil, members: [StorageMemberDTO]? = nil) {
        self.id = id
        self.owner = owner
        self.name = name
        self.items = items
        self.members = members
    }
    
    func toDomain() -> Storage {
        Storage(from: self)
    }
}

// MARK: - Storage Item DTOs

struct AddItemRequestDTO: Codable {
    let productId: Int
    let expiresAt: String // ISO 8601 date format
}

struct EditItemRequestDTO: Codable {
    let expiresAt: String?
}

struct StorageItemDTO: Codable {
    let id: Int
    let storage: StorageDTO?
    let product: ProductDTO?
    let expiresAt: String?
    let createdAt: String?

    init(id: Int, storage: StorageDTO?, product: ProductDTO?, expiresAt: String?, createdAt: String?) {
        self.id = id
        self.storage = storage
        self.product = product
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }
    
    func toDomain() -> StorageItem {
        StorageItem(from: self)
    }
}

// MARK: - Storage Member DTOs

struct InviteMemberRequestDTO: Codable {
    let email: String
}

struct StorageMemberDTO: Codable {
    let id: Int
    let user: UserDTO
    let storage: StorageDTO?
    let isAccepted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case user
        case storage
        case isAccepted
        case accepted
    }

    init(id: Int, user: UserDTO, storage: StorageDTO?, isAccepted: Bool) {
        self.id = id
        self.user = user
        self.storage = storage
        self.isAccepted = isAccepted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        user = try container.decode(UserDTO.self, forKey: .user)
        storage = try container.decodeIfPresent(StorageDTO.self, forKey: .storage)
        isAccepted = try container.decodeIfPresent(Bool.self, forKey: .isAccepted)
            ?? container.decodeIfPresent(Bool.self, forKey: .accepted)
            ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encodeIfPresent(storage, forKey: .storage)
        try container.encode(isAccepted, forKey: .accepted)
    }
    
    func toDomain() -> StorageMember {
        StorageMember(from: self)
    }
}

// MARK: - Shopping List DTOs

struct CreateShoppingItemRequestDTO: Codable {
    let productId: Int
    let amountToBuy: Int
}

struct EditShoppingItemRequestDTO: Codable {
    let amountToBuy: Int
}

struct ShoppingListItemDTO: Codable {
    let id: Int
    let storage: StorageDTO?
    let product: ProductDTO?
    let amountToBuy: Int

    init(id: Int, storage: StorageDTO?, product: ProductDTO?, amountToBuy: Int) {
        self.id = id
        self.storage = storage
        self.product = product
        self.amountToBuy = amountToBuy
    }
    
    func toDomain() -> ShoppingListItem {
        ShoppingListItem(from: self)
    }
}

// MARK: - Domain Models (for UI use)

struct User: Identifiable, Codable, Hashable {
    var id: Int?
    var email: String?
    var username: String
    var isAdmin: Bool

    var serverId: Int? {
        get { id }
        set { id = newValue }
    }

    var admin: Bool {
        get { isAdmin }
        set { isAdmin = newValue }
    }

    init(username: String, email: String? = nil, admin: Bool = false, serverId: Int? = nil) {
        self.id = serverId
        self.email = email
        self.username = username
        self.isAdmin = admin
    }

    init(from dto: UserDTO) {
        self.id = dto.id
        self.email = dto.email
        self.username = dto.username
        self.isAdmin = dto.isAdmin
    }
}

struct Product: Identifiable, Codable, Hashable {
    var id: Int?
    var name: String
    var description: String?
    var category: String
    var barcode: String?
    var expirationDaysDelta: Int
    var owner: User?

    var serverId: Int? {
        get { id }
        set { id = newValue }
    }

    var ownerId: Int? { owner?.serverId }

    init(
        name: String,
        category: String = "",
        expirationDaysDelta: Int = 0,
        barcode: String? = nil,
        ownerId: Int? = nil,
        serverId: Int? = nil,
        description: String? = nil
    ) {
        self.id = serverId
        self.name = name
        self.description = description
        self.category = category
        self.barcode = barcode
        self.expirationDaysDelta = expirationDaysDelta
        self.owner = ownerId.map { User(username: "", serverId: $0) }
    }

    init(from dto: ProductDTO) {
        self.id = dto.id
        self.name = dto.name
        self.description = dto.description
        self.category = dto.category
        self.barcode = dto.barcode
        self.expirationDaysDelta = dto.expirationDaysDelta
        self.owner = dto.ownerId.map { User(username: "", serverId: $0) }
    }
}

struct RunningLowSetting: Identifiable, Codable, Hashable {
    var id: Int { productId ?? -1 }
    var productId: Int?
    var threshold: Int
}

final class Storage: Identifiable, Codable {
    var id: Int?
    var name: String
    var owner: User?
    var items: [StorageItem]
    var members: [StorageMember]
    var shoppingItems: [ShoppingListItem]
    var runningLowSettings: [RunningLowSetting]

    var serverId: Int? {
        get { id }
        set { id = newValue }
    }

    init(
        name: String,
        owner: User? = nil,
        serverId: Int? = nil,
        items: [StorageItem] = [],
        members: [StorageMember] = [],
        shoppingItems: [ShoppingListItem] = [],
        runningLowSettings: [RunningLowSetting] = []
    ) {
        self.id = serverId
        self.name = name
        self.owner = owner
        self.items = items
        self.members = members
        self.shoppingItems = shoppingItems
        self.runningLowSettings = runningLowSettings
    }

    convenience init(from dto: StorageDTO) {
        self.init(
            name: dto.name,
            owner: dto.owner.map { User(from: $0) },
            serverId: dto.id,
            items: dto.items?.map { StorageItem(from: $0) } ?? [],
            members: dto.members?.map { StorageMember(from: $0) } ?? [],
            shoppingItems: [],
            runningLowSettings: []
        )
    }
}

struct StorageItem: Identifiable, Codable {
    var id: Int?
    var product: Product?
    var storage: Storage?
    var expiresAt: Date?
    var createdAt: Date

    var serverId: Int? {
        get { id }
        set { id = newValue }
    }

    init(product: Product? = nil, expiresAt: Date? = nil, serverId: Int? = nil, createdAt: Date = Date()) {
        self.id = serverId
        self.product = product
        self.storage = nil
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }

    init(from dto: StorageItemDTO) {
        self.id = dto.id
        self.product = dto.product.map { Product(from: $0) }
        self.storage = dto.storage.map { Storage(from: $0) }
        self.expiresAt = StorageItem.parseDate(dto.expiresAt)
        self.createdAt = StorageItem.parseDate(dto.createdAt) ?? Date()
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) {
            return date
        }

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: value)
    }
}

struct StorageMember: Identifiable, Codable {
    var id: Int?
    var user: User?
    var isAccepted: Bool

    var accepted: Bool {
        get { isAccepted }
        set { isAccepted = newValue }
    }

    init(from dto: StorageMemberDTO) {
        self.id = dto.id
        self.user = User(from: dto.user)
        self.isAccepted = dto.isAccepted
    }
}

struct ShoppingListItem: Identifiable, Codable {
    var id: Int?
    var product: Product?
    var storage: Storage?
    var amountToBuy: Int

    var serverId: Int? {
        get { id }
        set { id = newValue }
    }

    init(storage: Storage? = nil, product: Product? = nil, amountToBuy: Int = 1, serverId: Int? = nil) {
        self.id = serverId
        self.product = product
        self.storage = storage
        self.amountToBuy = amountToBuy
    }

    init(from dto: ShoppingListItemDTO) {
        self.id = dto.id
        self.product = dto.product.map { Product(from: $0) }
        self.storage = dto.storage.map { Storage(from: $0) }
        self.amountToBuy = dto.amountToBuy
    }
}
