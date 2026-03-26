# Services Documentation

## Overview

The iOS app currently has three core services:

- `APIService.swift` - backend HTTP client + DTO mapping
- `AuthService.swift` - auth/session token handling
- `LocalNotificationService.swift` - local iOS notification scheduling

## APIService

`APIService` wraps ShelfLife backend endpoints and exposes async methods used by contexts.

Current coverage includes:

- storages (with search/pagination support)
- products (with search/pagination support)
- storage items
- storage members + invites
- shopping list (per-storage and aggregated)
- running-low settings + running-low notifications
- expired/about-to-expire notifications
- image endpoints (`/icon/small`, `/pfp/small`)

### Important behavior

- Uses bearer token when available
- Supports both paged and unpaged list loading
- Maps DTO models to domain structs used by views/contexts

## AuthService

`AuthService` is responsible for:

- login (`/api/auth/login`)
- signup (`/api/auth/signup`)
- fetch current user (`/api/auth/me`)
- logout (`/api/auth/logout`)
- secure token storage (Keychain)

It exposes `AuthError` for UI-friendly validation and auth failure handling.

## LocalNotificationService

`LocalNotificationService` encapsulates local iOS notifications used by the app to surface important events in native notification center.

## Error handling

Network/service errors propagate as `APIError` / `AuthError` and are handled in contexts/views with user-facing messages.

## Notes

- Service methods are consumed from `Contexts/` to keep views thin.
- When backend endpoint contracts change, update `APIService` DTOs first, then context/view logic.
