//
//  DTOEdgeCaseTests.swift
//  shelfappTests
//
//  Additional DTO tests covering edge cases, date parsing, and round trips.
//

import Testing
import Foundation
@testable import shelfapp

// MARK: - StorageItemDTO Date Parsing Tests

struct StorageItemDTODateParsingTests {

    @Test func parsesLocalDateFormat() {
        let dto = StorageItemDTO(id: 1, storage: nil, product: nil, expiresAt: "2026-03-15", createdAt: "2026-02-27T10:00:00Z")
        let item = dto.toDomain()

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: item.expiresAt!)
        #expect(components.year == 2026)
        #expect(components.month == 3)
        #expect(components.day == 15)
    }

    @Test func parsesISO8601ExpiresAt() {
        let dto = StorageItemDTO(id: 1, storage: nil, product: nil, expiresAt: "2026-03-15T00:00:00Z", createdAt: "2026-02-27T10:00:00Z")
        let item = dto.toDomain()
        #expect(item.expiresAt != nil)
    }

    @Test func parsesCreatedAtWithFractionalSeconds() {
        let dto = StorageItemDTO(id: 1, storage: nil, product: nil, expiresAt: nil, createdAt: "2026-02-27T10:30:45.123Z")
        let item = dto.toDomain()
        #expect(item.createdAt <= Date())
    }

    @Test func parsesCreatedAtWithoutFractionalSeconds() {
        let dto = StorageItemDTO(id: 1, storage: nil, product: nil, expiresAt: nil, createdAt: "2026-02-27T10:30:45Z")
        let item = dto.toDomain()
        #expect(item.createdAt <= Date())
    }

    @Test func invalidCreatedAtFallsBackToNow() {
        let dto = StorageItemDTO(id: 1, storage: nil, product: nil, expiresAt: nil, createdAt: "not-a-date")
        let before = Date()
        let item = dto.toDomain()
        let after = Date()
        #expect(item.createdAt >= before.addingTimeInterval(-1))
        #expect(item.createdAt <= after.addingTimeInterval(1))
    }

    @Test func nilExpiresAtConvertsToNilDate() {
        let dto = StorageItemDTO(id: 1, storage: nil, product: nil, expiresAt: nil, createdAt: "2026-02-27T10:00:00Z")
        let item = dto.toDomain()
        #expect(item.expiresAt == nil)
    }
}

// MARK: - DTO with Nested Product Tests

struct DTONestedProductTests {

    @Test func storageItemDTOPreservesNestedProduct() {
        let productDTO = ProductDTO(id: 99, ownerId: 5, name: "Eggs", category: "Dairy", expirationDaysDelta: 21, barcode: "EGG123")
        let dto = StorageItemDTO(id: 10, storage: nil, product: productDTO, expiresAt: "2026-04-01", createdAt: "2026-03-01T00:00:00Z")
        let item = dto.toDomain()

        #expect(item.product?.name == "Eggs")
        #expect(item.product?.category == "Dairy")
        #expect(item.product?.expirationDaysDelta == 21)
        #expect(item.product?.barcode == "EGG123")
        #expect(item.product?.serverId == 99)
        #expect(item.serverId == 10)
    }

    @Test func shoppingListItemDTOPreservesNestedObjects() {
        let storageDTO = StorageDTO(id: 5, name: "Pantry", owner: UserDTO(id: 1, username: "admin", admin: true))
        let productDTO = ProductDTO(id: 8, ownerId: nil, name: "Salt", category: "Seasoning", expirationDaysDelta: 999, barcode: nil)
        let dto = ShoppingListItemDTO(id: 20, storage: storageDTO, product: productDTO, amountToBuy: 3)
        let item = dto.toDomain()

        #expect(item.storage?.name == "Pantry")
        #expect(item.storage?.serverId == 5)
        #expect(item.storage?.owner?.username == "admin")
        #expect(item.product?.name == "Salt")
        #expect(item.amountToBuy == 3)
        #expect(item.serverId == 20)
    }
}

// MARK: - DTO JSON Encoding Round Trip Tests

struct DTORoundTripTests {

    @Test func productDTORoundTrip() throws {
        let original = ProductDTO(id: 1, ownerId: 5, name: "Apple", category: "Fruit", expirationDaysDelta: 10, barcode: "ABC")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProductDTO.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.category == original.category)
        #expect(decoded.barcode == original.barcode)
    }

    @Test func storageDTORoundTrip() throws {
        let owner = UserDTO(id: 1, username: "owner", admin: false)
        let original = StorageDTO(id: 42, name: "Fridge", owner: owner)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StorageDTO.self, from: data)
        #expect(decoded.id == 42)
        #expect(decoded.name == "Fridge")
        #expect(decoded.owner?.username == "owner")
    }

    @Test func storageMemberDTORoundTrip() throws {
        let user = UserDTO(id: 3, username: "member", admin: false)
        let storage = StorageDTO(id: 1, name: "Main", owner: nil)
        let original = StorageMemberDTO(id: 5, storage: storage, user: user, accepted: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StorageMemberDTO.self, from: data)
        #expect(decoded.id == 5)
        #expect(decoded.user.username == "member")
        #expect(decoded.accepted == true)
    }

    @Test func loginResponseDTORoundTrip() throws {
        let original = LoginResponseDTO(token: "eyJ.test.sig")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LoginResponseDTO.self, from: data)
        #expect(decoded.token == "eyJ.test.sig")
    }

    @Test func signupErrorDTORoundTrip() throws {
        let original = SignupErrorDTO(username: "taken", email: nil, password: nil, passwordRepeat: nil, error: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SignupErrorDTO.self, from: data)
        #expect(decoded.username == "taken")
        #expect(decoded.email == nil)
    }
}

// MARK: - Product Domain Conversion Edge Cases

struct ProductDomainConversionTests {

    @Test func productDTOWithNilOwnerIdConverts() {
        let dto = ProductDTO(id: 1, ownerId: nil, name: "Water", category: "Beverage", expirationDaysDelta: 0, barcode: nil)
        let product = dto.toDomain()
        #expect(product.name == "Water")
        #expect(product.ownerId == nil)
        #expect(product.barcode == nil)
    }

    @Test func productDTOWithZeroExpiration() {
        let dto = ProductDTO(id: 2, ownerId: nil, name: "Can", category: "Preserved", expirationDaysDelta: 0, barcode: nil)
        let product = dto.toDomain()
        #expect(product.expirationDaysDelta == 0)
    }

    @Test func productDTOWithLongExpiration() {
        let dto = ProductDTO(id: 3, ownerId: nil, name: "Honey", category: "Sweetener", expirationDaysDelta: 3650, barcode: nil)
        let product = dto.toDomain()
        #expect(product.expirationDaysDelta == 3650)
    }
}
