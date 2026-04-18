# ShelfApp (iOS)

Native iOS client for ShelfLife, built with SwiftUI. The app mirrors backend and web functionality for storages, products, shopping lists, invites, running-low, and expiry notifications.

## Requirements

- Xcode 16+
- iOS 17+ simulator/device
- Running backend (`Backend/` project)

## Setup

1. Start backend API (`http://localhost:8080` by default).
2. Open `shelfapp.xcodeproj`.
3. Verify backend URL in `shelfapp/Utilities/AppConfig.swift`.
4. Build and run (`⌘R`).

For physical devices, use your machine LAN IP in `AppConfig.baseURL`.

## App Structure (Domain-first)

The iOS app is now organized by domain under `shelfapp/Domains/`.

Each domain uses the same pattern:

- `Store/` source-of-truth observable store (`@Observable`) and domain models
- `Page/` page file with **ViewModel at the top** and the SwiftUI page view below it
- `Components/` reusable subviews for that domain
- `Utils/API/` domain API protocol + default implementation
- `Utils/DTO/` backend DTO mapping types

### Domain map

- `Domains/Auth/`
	- `Store/AuthStore.swift`
	- `Page/RootPage.swift`, `Page/AuthPage.swift`
	- `Components/LoginFormView.swift`, `Components/SignupFormView.swift`
	- `Utils/API/AuthAPI.swift`, `Utils/API/DefaultAuthAPI.swift`
	- `Utils/DTO/AuthLoginDTO.swift`, `Utils/DTO/AuthSignupDTO.swift`, `Utils/DTO/UserAuthDTO.swift`
- `Domains/Home/`
	- `Page/HomePage.swift`
	- `Components/StatCard.swift`
- `Domains/Products/`
	- `Store/ProductsStore.swift`
	- `Page/ProductsPage.swift`
	- `Components/` product list/sheets/scanner
	- `Utils/API/ProductAPI.swift`
	- `Utils/DTO/ProductDTO.swift`
- `Domains/Storages/`
	- `Store/StorageStore.swift`
	- `Page/StoragesPage.swift`
	- `Components/` storage row/create/edit
	- `Utils/API/StorageAPI.swift`
	- `Utils/DTO/StorageDTO.swift`
- `Domains/ShoppingList/`
	- `Store/ShoppingListStore.swift`
	- `Page/ShoppingListPage.swift`
	- `Utils/API/ShoppingListAPI.swift`
	- `Utils/DTO/ShoppingListItemDTO.swift`
- `Domains/Notifications/`
	- `Store/NotificationsStore.swift`
	- `Page/NotificationsPage.swift`
	- `Utils/API/NotificationsAPI.swift`
	- `Utils/DTO/NotificationsDTO.swift`
- `Domains/Profile/`
	- `Store/ProfileStore.swift`
	- `Page/ProfilePage.swift`
	- `Components/` account/settings/edit
	- `Utils/API/ProfileAPI.swift`
- `Domains/StorageDetail/`
	- `Store/StorageDetailStore.swift`
	- `Page/StorageDetailPage.swift`
	- `Components/` item/member/invite/running-low sheets
	- `Utils/API/StorageDetailAPI.swift`
	- `Utils/DTO/StorageDetailDTOs.swift`
- `Domains/Shared/Components/`
	- shared UI components used across domains
- `Domains/Shared/APIError.swift`
	- centralized error enum for all API operations
- `Domains/Shared/SharedTypes.swift`
	- shared DTO wrappers, paginated response models, and `ResourceURLBuilder`

Domain-specific APIs:
- `Domains/Auth/Utils/API/AuthAPI.swift`
	- login, signup, me (fetch current user), logout
- `Domains/Products/Utils/API/ProductAPI.swift`
	- fetch/create/update/delete products, categories
- `Domains/Storages/Utils/API/StorageAPI.swift`
	- fetch/create/update/delete storages, pagination
- `Domains/ShoppingList/Utils/API/ShoppingListAPI.swift`
	- fetch/add/update/delete/complete shopping items
- `Domains/StorageDetail/Utils/API/StorageDetailAPI.swift`
	- storage items, members, invites, running-low settings
- `Domains/Notifications/Utils/API/NotificationsAPI.swift`
	- pending invites, running-low notifications, expiring items
- `Domains/Profile/Utils/API/ProfileAPI.swift`
	- profile update and profile picture upload

Cross-domain infra stays in:

- `shelfapp/Services/AuthService.swift` (secure token persistence, session bridge)
- `shelfapp/Services/LocalNotificationService.swift` (push notifications)
- `shelfapp/Utilities/` (config/date/navigation/image helpers)
- `shelfapp/Domains/Profile/Store/User.swift` (shared domain model)

## State Flow

- Store owns domain state.
- ViewModel does not duplicate domain entities; it coordinates user actions and view-only state.
- Page reads from VM/store and renders.

In short:

1. Page event → VM method
2. VM calls Store async API operation
3. Store mutates observable state
4. SwiftUI re-renders automatically

## API Architecture

All domain API operations are built on **Endpoint + HTTPClient**:

- **Endpoint** (`Protocols/Endpoint.swift`) = typed route, method, query and body definitions
- **DefaultHTTPClient** (`Protocols/DefaultHTTPClient.swift`) = request building + headers + status mapping + decoding
- **Domain APIs** (`Domains/{Domain}/Utils/API/*.swift`) = feature-scoped protocol + implementation that maps DTOs to domain models
- **AuthService** = token persistence bridge (Keychain only), while `AuthStore` owns runtime token state

Pattern:
```
Page → Store → DomainAPI → HTTPClient.request(Endpoint) → APIError handling
```

Auth flow:
```
AuthStore.login() → AuthAPI.login() → token stored in AuthStore + persisted via AuthService
```

## Error & Loading Handling

- Every domain store exposes `isLoading` and `errorMessage`.
- Every page binds UI feedback from store state:
	- loading spinners for long-running operations
	- domain-scoped error alerts
- Errors are reset after alert dismissal to avoid stale error banners.

This keeps network error handling consistent across all domains.

## Functionalities

- Authentication: signup, login, logout, session restore (`/api/auth/me`)
- Storages: list/search/paginate, create, edit, delete
- Products: list/search/paginate, create, edit, delete
- Storage detail: items, members, invite handling, running-low settings
- Shopping list: aggregated shopping list, amount edits, done/delete actions
- Notifications: invites + running-low + about-to-expire
- Badge logic: invites + unresolved running-low
- Images: product/user small icon endpoints for fast list rendering

## API Endpoints Used by iOS

- Auth: `/api/auth/*`
- Storages: `/api/storages`, `/api/storages/{id}`
- Storage items: `/api/storages/{id}/items`
- Members + invites: `/api/storages/{id}/members`, `/api/storages/invites`
- Products: `/api/products`, `/api/products/{id}/icon/small`
- Shopping list: `/api/shoppinglist`, `/api/storages/{id}/shoppinglist`
- Running low: `/api/runninglow`, `/api/storages/{id}/runninglow`, `/api/storages/{id}/runninglowsettings`
- Expiration: `/api/abouttoexpire`, `/api/expired`

## Testing

### Unit tests

Tests are reorganized by domain in `shelfappTests/`:

- `shelfappTests/Auth/`
- `shelfappTests/Core/`
- `shelfappTests/DTO/`
- `shelfappTests/Services/`
- `shelfappTests/Utilities/`

They are written with Swift Testing (`@Test`, `#expect`).

Run:

```bash
xcodebuild -scheme shelfapp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:shelfappTests
```

### UI tests

Located in `shelfappUITests/` and written with XCUITest.

Run:

```bash
xcodebuild -scheme shelfapp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:shelfappUITests
```

Authenticated UI flows expect test credentials to exist on the backend.
