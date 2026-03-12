# Shelf Life

A personal inventory management system for tracking food storages, products, and expiration dates. The project consists of a **Spring Boot** backend, a **React** web frontend, an **npm library** (shared contexts/hooks), and a native **iOS app** built with SwiftUI.

---

## Project Structure

```
shelflife/
├── Backend/          # Spring Boot REST API (Java 21, Maven)
├── Frontend/         # React + Vite web client (TypeScript)
├── package/          # Shared JS/TS library (contexts, hooks, types)
└── shelfapp/         # Native iOS app (SwiftUI + SwiftData)
```

---

## Backend

A Spring Boot application providing REST endpoints for authentication, storages, products, storage items, shopping lists, and invites.

### Tech Stack

- Java 21, Spring Boot, Spring Security (JWT)
- Maven, PostgreSQL
- Docker & Docker Compose

### Running with Docker

```bash
cd Backend
cp template.env .env        # fill in DB credentials and JWT secret
docker compose up --build
```

The API starts at `http://localhost:8080`.

### Key Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/signup` | Register |
| POST | `/api/auth/login` | Login → JWT token |
| GET | `/api/auth/me` | Current user info |
| GET | `/api/storages` | List storages |
| POST | `/api/storages` | Create storage |
| GET | `/api/storages/{id}/items` | Storage items |
| POST | `/api/storages/{id}/items` | Add item |
| GET | `/api/storages/{id}/shoppinglist` | Shopping list |
| GET | `/api/storages/{id}/members` | Storage members |
| POST | `/api/storages/{id}/members` | Invite member |
| GET | `/api/storages/invites` | Pending invites |
| GET | `/api/products` | List products |
| POST | `/api/products` | Create product |
| GET | `/api/products/{id}/icon/small` | Product icon (64×64) |
| GET | `/api/users/{id}/pfp/small` | User avatar (64×64) |

### Backend Tests

```bash
cd Backend
docker compose run --rm app mvn test
```

---

## Frontend (Web)

A React single-page application using the shared `package` library.

### Tech Stack

- React 18, TypeScript, Vite
- Context-based state management (via `package/`)

### Running

```bash
cd Frontend
cp template.env .env
npm install
npm run dev
```

Opens at `http://localhost:5173`.

---

## Package (Shared Library)

Reusable TypeScript contexts, hooks, and types consumed by the web frontend.

```bash
cd package
npm install
npm run build
npm test
```

---

## iOS App (`shelfapp`)

A native SwiftUI application targeting iOS 17+.

### Tech Stack

- SwiftUI, SwiftData (local persistence + API sync)
- Swift Testing framework for unit tests
- XCTest / XCUITest for UI tests
- Xcode 16+ (uses `PBXFileSystemSynchronizedRootGroup` — files on disk are auto-discovered)

### Architecture

```
shelfapp/
├── Features/
│   ├── Auth/              # LoginView, LoginFormView, SignupFormView, RootView
│   ├── Home/              # HomeView, StatCard
│   ├── Products/          # ProductsView, ProductListRow, CreateProductSheet
│   ├── Storages/          # StoragesView, StorageListRow, CreateStorageSheet
│   ├── StorageDetail/     # StorageDetailView, ItemRow, ShoppingItemRow,
│   │                      # MemberRow, PendingInviteRow, AddItemSheet, InviteMemberSheet
│   ├── Notifications/     # NotificationsView, InviteNotificationRow
│   ├── Profile/           # ProfileView, AppSettingsView
│   ├── Shopping/          # ShoppingListView
│   ├── Components/        # AnimatedSecureTextField
│   └── Models/            # Product, Storage, StorageItem, User, ShoppingListItem
├── Services/
│   ├── APIService.swift   # REST client + DTOs
│   ├── AuthService.swift  # Login/signup, token management
│   ├── AuthManager.swift  # Observable auth state
│   ├── SyncService.swift  # SwiftData ↔ API sync
│   └── DataService.swift  # Local seed data
├── Utilities/
│   ├── AppConfig.swift    # Base URL configuration
│   ├── RemoteImage.swift  # Cached async image loader
│   ├── AppGradientBackground.swift
│   ├── DateUtils.swift
│   └── NavigationMananger.swift
└── Resources/
    └── Assets.xcassets
```

### Features

- **Authentication**: Login / signup with JWT tokens stored in UserDefaults
- **Storages**: Create, delete, and share storages with other users
- **Products**: Browse and create products with categories and expiration info
- **Storage Items**: Add products to storages with expiry dates
- **Shopping Lists**: Track items to purchase per storage
- **Invitations**: Invite members, accept/decline storage invites
- **Remote Images**: Async cached image loading with placeholder fallback
- **Offline Support**: SwiftData local persistence, syncs on launch

### Configuration

Edit `Utilities/AppConfig.swift` to change the backend URL:

```swift
enum AppConfig {
    static let baseURL = "http://localhost:8080"       // Simulator
    // static let baseURL = "http://192.168.1.X:8080"  // Physical device
}
```

### Running

1. Open `shelfapp.xcodeproj` in Xcode 16+
2. Select an iOS 17+ simulator
3. Ensure the backend is running (`docker compose up` in `Backend/`)
4. Build & Run (⌘R)

### Tests

#### Unit Tests

Located in `shelfappTests/`. Use Swift Testing (`@Test`, `#expect`).

```
shelfappTests/
├── shelfappTests.swift               # Placeholder
├── APIServiceTests.swift             # API config, APIError, AuthError tests
├── AuthManagerTests.swift            # AuthManager state tests
├── AuthServiceValidationTests.swift  # Input validation, token management
├── DTOTests.swift                    # DTO decoding and domain conversion
├── DTOEdgeCaseTests.swift            # Date parsing, nested DTOs, round trips
├── ModelTests.swift                  # SwiftData model init, relationships, Codable
├── DateUtilsTests.swift              # Date.daysFromNow extension
├── ImageCacheTests.swift             # ImageCache + URL helpers
├── AppConfigTests.swift              # AppConfig validation
└── NavigationManagerTests.swift      # NavigationMananger tests
```

Run in Xcode: **Product → Test** (⌘U) or via command line:

```bash
xcodebuild test \
  -project shelfapp/shelfapp.xcodeproj \
  -scheme shelfapp \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

#### UI Tests

Located in `shelfappUITests/`. Use XCUITest.

```
shelfappUITests/
├── shelfappUITests.swift             # Login flow, authenticated flow (tabs, nav, logout)
├── AccessibilityUITests.swift        # Accessibility, keyboard, edge cases
└── shelfappUITestsLaunchTests.swift  # Launch screenshot test
```

> **Note:** Authenticated flow tests (`AuthenticatedFlowUITests`) require a running backend with test credentials (`test@test.com` / `test`). They are skipped automatically if login fails.

---

## Environment Setup

| Component | Requirement |
|-----------|-------------|
| Backend | Docker & Docker Compose |
| Frontend | Node.js 18+, npm |
| iOS App | Xcode 16+, iOS 17+ Simulator |

---

## License

Private project — all rights reserved.
