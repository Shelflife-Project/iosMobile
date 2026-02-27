//
//  ModelTests.swift
//  shelfappTests
//
//  Tests for SwiftData model initialization, relationships, and computed properties.
//

import Testing
import Foundation
@testable import shelfapp

// MARK: - User Model Tests

struct UserModelTests {

    @Test func userInitializesWithDefaults() {
        let user = User(username: "testuser")
        #expect(user.username == "testuser")
        #expect(user.email == nil)
        #expect(user.admin == false)
        #expect(user.serverId == nil)
    }

    @Test func userInitializesWithAllProperties() {
        let user = User(username: "admin", email: "admin@test.com", admin: true, serverId: 42)
        #expect(user.username == "admin")
        #expect(user.email == "admin@test.com")
        #expect(user.admin == true)
        #expect(user.serverId == 42)
    }

    @Test func userCodableRoundTrip() throws {
        let original = User(username: "coder", email: "coder@test.com", admin: false, serverId: 7)
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(User.self, from: data)
        #expect(decoded.username == original.username)
        #expect(decoded.email == original.email)
        #expect(decoded.admin == original.admin)
        #expect(decoded.serverId == original.serverId)
        #expect(decoded.id == original.id)
    }

    @Test func userDecodesWithMissingOptionals() throws {
        let json = """
        {"id": "550e8400-e29b-41d4-a716-446655440000", "username": "minimal"}
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(User.self, from: data)
        #expect(decoded.username == "minimal")
        #expect(decoded.email == nil)
        #expect(decoded.admin == false)
        #expect(decoded.serverId == nil)
    }
}

// MARK: - Product Model Tests

struct ProductModelTests {

    @Test func productInitializesWithDefaults() {
        let product = Product(name: "Milk")
        #expect(product.name == "Milk")
        #expect(product.category == "")
        #expect(product.expirationDaysDelta == 0)
        #expect(product.barcode == nil)
        #expect(product.ownerId == nil)
    }

    @Test func productInitializesWithAllProperties() {
        let ownerId = UUID()
        let product = Product(
            name: "Yogurt",
            category: "Dairy",
            expirationDaysDelta: 14,
            barcode: "1234567890",
            ownerId: ownerId
        )
        #expect(product.name == "Yogurt")
        #expect(product.category == "Dairy")
        #expect(product.expirationDaysDelta == 14)
        #expect(product.barcode == "1234567890")
        #expect(product.ownerId == ownerId)
    }
}

// MARK: - Storage Model Tests

struct StorageModelTests {

    @Test func storageInitializesWithDefaults() {
        let storage = Storage(name: "Fridge")
        #expect(storage.name == "Fridge")
        #expect(storage.owner == nil)
        #expect(storage.serverId == nil)
        #expect(storage.items.isEmpty)
        #expect(storage.shoppingItems.isEmpty)
    }

    @Test func storageInitializesWithOwnerAndServerId() {
        let owner = User(username: "owner", serverId: 1)
        let storage = Storage(name: "Pantry", owner: owner, serverId: 99)
        #expect(storage.name == "Pantry")
        #expect(storage.owner?.username == "owner")
        #expect(storage.serverId == 99)
    }
}

// MARK: - StorageItem Model Tests

struct StorageItemModelTests {

    @Test func storageItemInitializesWithDefaults() {
        let item = StorageItem()
        #expect(item.product == nil)
        #expect(item.expiresAt == nil)
        #expect(item.createdAt <= Date())
    }

    @Test func storageItemInitializesWithProduct() {
        let product = Product(name: "Bread", category: "Bakery", expirationDaysDelta: 5)
        let expiry = Date().addingTimeInterval(5 * 24 * 3600)
        let item = StorageItem(product: product, expiresAt: expiry)
        #expect(item.product?.name == "Bread")
        #expect(item.expiresAt != nil)
    }
}

// MARK: - ShoppingListItem Model Tests

struct ShoppingListItemModelTests {

    @Test func shoppingListItemInitializesWithDefaults() {
        let item = ShoppingListItem()
        #expect(item.storage == nil)
        #expect(item.product == nil)
        #expect(item.amountToBuy == 1)
    }

    @Test func shoppingListItemInitializesWithValues() {
        let product = Product(name: "Eggs")
        let storage = Storage(name: "Home")
        let item = ShoppingListItem(storage: storage, product: product, amountToBuy: 3)
        #expect(item.storage?.name == "Home")
        #expect(item.product?.name == "Eggs")
        #expect(item.amountToBuy == 3)
    }
}
