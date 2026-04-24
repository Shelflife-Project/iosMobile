# ShelfApp – iOS

> **Magyar** | [English](#english)

---

## Magyar

### Mi ez az alkalmazás?

A **ShelfLife** egy háztartási készletkezelő rendszer. Az iOS alkalmazás lehetővé teszi, hogy:

- Nyomon kövesd a tárolt tárgyakat (hűtő, kamra, stb.)
- Figyelemmel kísérd a lejárati dátumokat és kapj értesítést a hamarosan lejáró termékekről
- Kezelj megosztott tárhelyeket más felhasználókkal (meghívók, tagkezelés)
- Automatikusan generált bevásárlólistát használj a fogyóban lévő termékek alapján
- Értesítéseket kapj a fogyóban lévő és hamarosan lejáró termékekről

---

### Rendszerkövetelmények

| Komponens | Minimum verzió |
|-----------|---------------|
| iOS | 17.0 |
| Xcode | 16.0+ |
| Swift | 5.9+ |
| Backend (Java) | 21+ |
| MySQL | 8.0 |

A backend alapértelmezés szerint `http://localhost:8080` címen fut. Fizikai eszköz esetén a LAN IP-t kell megadni az `AppConfig.swift` fájlban.

---

### Az IPA telepítése (`shelfapp-unsigned.ipa`)

Az IPA fájl aláírás nélküli – **csak fejlesztői célra** készült, nem tölthető fel az App Store-ba.

#### 1. lehetőség – AltStore (ajánlott)

1. Telepítsd az [AltStore](https://altstore.io)-t a számítógépedre és az iPhone-ra.
2. Csatlakoztasd az iPhone-t USB-vel.
3. Nyisd meg az AltStore-t az iPhone-on → **My Apps** → **+** gomb.
4. Válaszd ki a `shelfapp-unsigned.ipa` fájlt.
5. Az AltStore saját Apple ID-vel aláírja és telepíti.
6. Az alkalmazás 7 napig érvényes; az AltStore automatikusan megújítja, ha Wi-Fi-n csatlakozol.

#### 2. lehetőség – Xcode (fejlesztői gép)

1. Csatlakoztasd az iPhone-t USB-vel, és bízd meg a számítógépedet az eszközön.
2. Nyisd meg a `shelfapp.xcodeproj` fájlt Xcode-ban.
3. A **Signing & Capabilities** fülön válaszd ki a saját csapatodat (személyes Apple ID is megfelelő).
4. Válaszd ki az eszközt a célként, majd nyomd meg a **▶ Run** gombot (`⌘R`).

#### 3. lehetőség – Apple Configurator 2 (macOS)

1. Telepítsd az **Apple Configurator 2** alkalmazást a Mac App Store-ból.
2. Csatlakoztasd az iPhone-t USB-vel.
3. Húzd rá az IPA fájlt az eszközre az Apple Configurator ablakában.
4. Fogadd el a telepítési kérelmet az iPhone-on.

> **Megjegyzés:** Aláíratlan IPA-t csak fejlesztői módban lévő, vagy jailbreakelt eszközre lehet közvetlenül telepíteni. Normál készülékeken az AltStore vagy Xcode aláírása szükséges.

---

### Fejlesztői indítás (forráskódból)

```bash
# Backend elindítása
cd Backend
./mvnw spring-boot:run

# iOS app megnyitása
open shelfapp/shelfapp.xcodeproj
# Majd ⌘R a Xcode-ban
```

A backend URL beállítása: `shelfapp/Utilities/AppConfig.swift`

---

---

## English

### What is this app?

**ShelfLife** is a household inventory management system. The iOS app lets you:

- Track items across physical storage locations (fridge, pantry, etc.)
- Monitor expiration dates and receive notifications for soon-to-expire products
- Manage shared storages with other users (invitations, member management)
- Use an auto-generated shopping list based on low-stock items
- Get notified about items running low or about to expire

---

### System Requirements

| Component | Minimum Version |
|-----------|----------------|
| iOS | 17.0 |
| Xcode | 16.0+ |
| Swift | 5.9+ |
| Backend (Java) | 21+ |
| MySQL | 8.0 |

The backend runs at `http://localhost:8080` by default. For physical devices, set your LAN IP in `AppConfig.swift`.

---

### Installing the IPA (`shelfapp-unsigned.ipa`)

The IPA is unsigned — it is **for development use only** and cannot be submitted to the App Store.

#### Option 1 – AltStore (recommended)

1. Install [AltStore](https://altstore.io) on your Mac and iPhone.
2. Connect your iPhone via USB.
3. Open AltStore on the iPhone → **My Apps** → tap **+**.
4. Select `shelfapp-unsigned.ipa`.
5. AltStore signs and installs it using your Apple ID.
6. The app is valid for 7 days; AltStore auto-renews it when the iPhone is on the same Wi-Fi as your Mac.

#### Option 2 – Xcode (developer machine)

1. Connect your iPhone via USB and trust the computer on the device.
2. Open `shelfapp.xcodeproj` in Xcode.
3. Under **Signing & Capabilities**, select your team (a personal Apple ID works).
4. Choose your device as the run destination and press **▶ Run** (`⌘R`).

#### Option 3 – Apple Configurator 2 (macOS)

1. Install **Apple Configurator 2** from the Mac App Store.
2. Connect your iPhone via USB.
3. Drag the IPA file onto the device in Apple Configurator's window.
4. Accept the installation prompt on the iPhone.

> **Note:** Unsigned IPAs can only be installed directly on developer-mode or jailbroken devices. On a standard device, AltStore or Xcode signing is required.

---

### Running from Source

```bash
# Start the backend
cd Backend
./mvnw spring-boot:run

# Open the iOS project
open shelfapp/shelfapp.xcodeproj
# Then press ⌘R in Xcode
```

Backend URL configuration: `shelfapp/Utilities/AppConfig.swift`

---

## App Structure (Domain-first)

The iOS app is organized by domain under `shelfapp/Domains/`.

Each domain follows the same pattern:

- `Store/` — source-of-truth observable store (`@Observable`) and domain models
- `Page/` — page file with **ViewModel at the top** and the SwiftUI view below it
- `Components/` — reusable subviews for that domain
- `Utils/API/` — domain API protocol + default implementation + HTTP client wrapper
- `Utils/DTO/` — backend DTO mapping types

### Domain map

- `Domains/Auth/` — login, signup, session restore, logout
- `Domains/Home/` — dashboard with inventory stats
- `Domains/Products/` — product list, search, create/edit/delete, barcode scanner
- `Domains/Storages/` — storage list, create/edit/delete, pagination
- `Domains/StorageDetail/` — items, members, invites, running-low settings
- `Domains/ShoppingList/` — aggregated shopping list, amount edits, done/delete
- `Domains/Notifications/` — pending invites, running-low, about-to-expire
- `Domains/Profile/` — profile update, profile picture upload
- `Domains/Shared/` — shared UI components, error types, shared DTO wrappers

Cross-domain infrastructure:

- `shelfapp/Services/AuthService.swift` — secure token persistence (Keychain)
- `shelfapp/Services/LocalNotificationService.swift` — push notifications
- `shelfapp/Utilities/` — config, date, navigation, image helpers

## State Flow

```
Page event → VM method → Store async operation → observable state mutation → SwiftUI re-render
```

Every domain store exposes `isLoading: Bool` and `errorMessage: String?`; pages bind these to loading spinners and alert views.

## Testing

```bash
# Unit tests
xcodebuild -scheme shelfapp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:shelfappTests

# UI tests
xcodebuild -scheme shelfapp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:shelfappUITests
```
