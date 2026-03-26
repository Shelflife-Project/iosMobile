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

## App Structure

- `shelfapp/Features/` screen-level SwiftUI views
- `shelfapp/Contexts/` observable state managers per domain
- `shelfapp/Services/` API, auth, and local notification services
- `shelfapp/Utilities/` app config, date helpers, image helper, navigation helper

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

Located in `shelfappTests/` and written with Swift Testing (`@Test`, `#expect`).

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
