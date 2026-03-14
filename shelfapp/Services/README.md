# Services Documentation

## APIService

The `APIService` provides direct HTTP communication with the Shelf Life backend API.

### Configuration

```swift
import SwiftUI
import SwiftData


@main
struct shelfappApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onAppear {
            // Configure the API service (set baseURL and optional auth token)
            APIService.shared.configure(
                baseURL: "http://localhost:8080",
                token: nil // Add your auth token here if available
            )
        }
    }
}
```

### Available Methods

#### Storage Operations
- `fetchStorages()` - Get all storages
- `fetchStorage(id:)` - Get a specific storage
- `createStorage(name:)` - Create a new storage
- `updateStorageName(id:name:)` - Update storage name
- `deleteStorage(id:)` - Delete a storage

#### Product Operations
- `fetchProducts()` - Get all products
- `createProduct(name:category:expirationDaysDelta:)` - Create a product

#### Storage Item Operations
- `fetchStorageItems(storageId:)` - Get items in a storage
- `addStorageItem(storageId:productId:expiresAt:)` - Add item to storage
- `deleteStorageItem(storageId:itemId:)` - Remove item from storage

#### Shopping List Operations
- `fetchShoppingItems(storageId:)` - Get shopping list items
- `addShoppingItem(storageId:productId:amountToBuy:)` - Add shopping item
- `deleteShoppingItem(storageId:itemId:)` - Remove shopping item

### Usage Example

```swift
// Fetch storages from API
let storages = try await APIService.shared.fetchStorages()

// Create a new storage
let newStorage = try await APIService.shared.createStorage(name: "Pantry")

// Add product to storage
let item = try await APIService.shared.addStorageItem(
    storageId: storageId,
    productId: productId,
    expiresAt: Date().addingTimeInterval(7 * 24 * 3600)
)
```

## SyncService

The `SyncService` handles syncing between the API and SwiftData local persistence. It provides high-level operations that keep both layers in sync.

### Available Methods

#### Sync Operations
- `syncStorages(in:)` - Download all storages from API to local SwiftData
- `syncStorageItems(for:in:)` - Download items for a specific storage

#### Create (with automatic sync)
- `createStorageAndSync(name:in:)` - Create storage on API and save locally
- `addProductAndSync(name:category:expirationDaysDelta:in:)` - Create product and sync
- `addStorageItemAndSync(to:product:expiresAt:in:)` - Add item and sync
- `addShoppingItemAndSync(to:product:amountToBuy:in:)` - Add shopping item and sync

#### Delete (with automatic sync)
- `deleteStorageAndSync(_:in:)` - Delete storage from API and local
- `deleteStorageItemAndSync(_:from:in:)` - Delete item from API and local
- `deleteShoppingItemAndSync(_:from:in:)` - Delete shopping item from API and local

### Usage Example

```swift
@Environment(\.modelContext) var modelContext

// Sync all storages from backend
try await SyncService.shared.syncStorages(in: modelContext)

// Create a storage (automatically syncs with backend)
let newStorage = try await SyncService.shared.createStorageAndSync(
    name: "Fridge",
    in: modelContext
)

// Add item to storage (automatically syncs)
let item = try await SyncService.shared.addStorageItemAndSync(
    to: storage,
    product: product,
    expiresAt: Date().addingTimeInterval(7 * 24 * 3600),
    in: modelContext
)
```

## Error Handling

All async methods throw `APIError` which conforms to `LocalizedError`:

```swift
do {
    let storages = try await APIService.shared.fetchStorages()
} catch let error as APIError {
    print(error.errorDescription ?? "Unknown error")
} catch {
    print("Unexpected error: \(error)")
}
```

### Error Types
- `.invalidURL` - Malformed URL
- `.networkError(Error)` - Network connectivity issue
- `.invalidResponse` - Invalid HTTP response
- `.decodingError(Error)` - JSON decoding failed
- `.unauthorized` - 401 Unauthorized
- `.notFound` - 404 Not Found
- `.serverError(statusCode:)` - 5xx server error
- `.unknown` - Unknown error

## Architecture Notes

- **APIService**: Stateless, handles raw HTTP communication and DTO transformation
- **SyncService**: Uses APIService internally, manages SwiftData context operations
- **DTOs**: Data Transfer Objects (StorageDTO, ProductDTO, etc.) handle API serialization
- **Models**: SwiftData @Model classes represent local domain entities

Start with `DataService` for seeding/testing, use `APIService` for direct API calls, and use `SyncService` for keeping local data in sync with the backend.
