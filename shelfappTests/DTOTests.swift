//
//  DTOTests.swift
//  shelfappTests
//
//  Tests for DTO decoding and domain conversion.
//

import Testing
import Foundation
@testable import shelfapp

// MARK: - UserDTO Tests

struct UserDTOTests {

    @Test func userDTODecodesCorrectly() throws {
        let json = """
        {"id": 1, "username": "testuser", "admin": false}
        """
        let dto = try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
        #expect(dto.id == 1)
        #expect(dto.username == "testuser")
        #expect(dto.admin == false)
    }

    @Test func userDTOConvertsToDomain() {
        let dto = UserDTO(id: 5, username: "alice", admin: true)
        let user = dto.toDomain()
        #expect(user.username == "alice")
        #expect(user.admin == true)
        #expect(user.serverId == 5)
    }
}

// MARK: - StorageDTO Tests

struct StorageDTOTests {

    @Test func storageDTODecodesCorrectly() throws {
        let json = """
        {"id": 10, "name": "Fridge", "owner": {"id": 1, "username": "bob", "admin": false}}
        """
        let dto = try JSONDecoder().decode(StorageDTO.self, from: Data(json.utf8))
        #expect(dto.id == 10)
        #expect(dto.name == "Fridge")
        #expect(dto.owner?.username == "bob")
    }

    @Test func storageDTOConvertsToDomain() {
        let ownerDTO = UserDTO(id: 1, username: "owner", admin: false)
        let dto = StorageDTO(id: 42, name: "Pantry", owner: ownerDTO)
        let storage = dto.toDomain()
        #expect(storage.name == "Pantry")
        #expect(storage.serverId == 42)
        #expect(storage.owner?.username == "owner")
        #expect(storage.owner?.serverId == 1)
    }

    @Test func storageDTODecodesWithNullOwner() throws {
        let json = """
        {"id": 3, "name": "Shared", "owner": null}
        """
        let dto = try JSONDecoder().decode(StorageDTO.self, from: Data(json.utf8))
        #expect(dto.name == "Shared")
        #expect(dto.owner == nil)

        let storage = dto.toDomain()
        #expect(storage.owner == nil)
    }
}

// MARK: - ProductDTO Tests

struct ProductDTOTests {

    @Test func productDTODecodesCorrectly() throws {
        let json = """
        {"id": 7, "ownerId": 1, "name": "Milk", "category": "Dairy", "expirationDaysDelta": 7, "barcode": "12345"}
        """
        let dto = try JSONDecoder().decode(ProductDTO.self, from: Data(json.utf8))
        #expect(dto.id == 7)
        #expect(dto.name == "Milk")
        #expect(dto.category == "Dairy")
        #expect(dto.expirationDaysDelta == 7)
        #expect(dto.barcode == "12345")
    }

    @Test func productDTOConvertsToDomain() {
        let dto = ProductDTO(id: 1, ownerId: nil, name: "Bread", category: "Bakery", expirationDaysDelta: 3, barcode: nil)
        let product = dto.toDomain()
        #expect(product.name == "Bread")
        #expect(product.category == "Bakery")
        #expect(product.expirationDaysDelta == 3)
        #expect(product.barcode == nil)
    }
}

// MARK: - StorageItemDTO Tests

struct StorageItemDTOTests {

    @Test func storageItemDTODecodesCorrectly() throws {
        let json = """
        {"id": 1, "product": {"id": 2, "ownerId": null, "name": "Cheese", "category": "Dairy", "expirationDaysDelta": 14, "barcode": null}, "expiresAt": "2026-03-15T00:00:00Z", "createdAt": "2026-02-27T10:00:00Z"}
        """
        let dto = try JSONDecoder().decode(StorageItemDTO.self, from: Data(json.utf8))
        #expect(dto.id == 1)
        #expect(dto.product?.name == "Cheese")
        #expect(dto.expiresAt == "2026-03-15T00:00:00Z")
    }

    @Test func storageItemDTOConvertsToDomain() {
        let productDTO = ProductDTO(id: 1, ownerId: nil, name: "Butter", category: "Dairy", expirationDaysDelta: 30, barcode: nil)
        let dto = StorageItemDTO(id: 5, product: productDTO, expiresAt: "2026-04-01T00:00:00Z", createdAt: "2026-02-27T12:00:00Z")
        let item = dto.toDomain()
        #expect(item.product?.name == "Butter")
        #expect(item.expiresAt != nil)
        #expect(item.createdAt <= Date())
    }

    @Test func storageItemDTOHandlesNullExpiry() {
        let dto = StorageItemDTO(id: 1, product: nil, expiresAt: nil, createdAt: "2026-02-27T12:00:00Z")
        let item = dto.toDomain()
        #expect(item.product == nil)
        #expect(item.expiresAt == nil)
    }
}

// MARK: - ShoppingListItemDTO Tests

struct ShoppingListItemDTOTests {

    @Test func shoppingListItemDTODecodesCorrectly() throws {
        let json = """
        {"id": 1, "storage": {"id": 10, "name": "Home", "owner": null}, "product": {"id": 2, "ownerId": null, "name": "Rice", "category": "Grains", "expirationDaysDelta": 365, "barcode": null}, "amountToBuy": 2}
        """
        let dto = try JSONDecoder().decode(ShoppingListItemDTO.self, from: Data(json.utf8))
        #expect(dto.id == 1)
        #expect(dto.product?.name == "Rice")
        #expect(dto.amountToBuy == 2)
    }

    @Test func shoppingListItemDTOConvertsToDomain() {
        let storageDTO = StorageDTO(id: 1, name: "Kitchen", owner: nil)
        let productDTO = ProductDTO(id: 2, ownerId: nil, name: "Pasta", category: "Grains", expirationDaysDelta: 180, barcode: nil)
        let dto = ShoppingListItemDTO(id: 3, storage: storageDTO, product: productDTO, amountToBuy: 5)
        let item = dto.toDomain()
        #expect(item.product?.name == "Pasta")
        #expect(item.amountToBuy == 5)
    }
}

// MARK: - StorageMemberDTO Tests

struct StorageMemberDTOTests {

    @Test func storageMemberDTODecodesCorrectly() throws {
        let json = """
        {"id": 1, "storage": {"id": 10, "name": "Shared Fridge", "owner": null}, "user": {"id": 5, "username": "member1", "admin": false}, "accepted": true}
        """
        let dto = try JSONDecoder().decode(StorageMemberDTO.self, from: Data(json.utf8))
        #expect(dto.id == 1)
        #expect(dto.user.username == "member1")
        #expect(dto.accepted == true)
        #expect(dto.storage?.name == "Shared Fridge")
    }

    @Test func storageMemberDTODecodesPendingInvite() throws {
        let json = """
        {"id": 2, "storage": {"id": 10, "name": "Kitchen", "owner": null}, "user": {"id": 6, "username": "invitee", "admin": false}, "accepted": false}
        """
        let dto = try JSONDecoder().decode(StorageMemberDTO.self, from: Data(json.utf8))
        #expect(dto.id == 2)
        #expect(dto.accepted == false)
        #expect(dto.user.username == "invitee")
    }
}

// MARK: - StorageMemberInfo Tests

struct StorageMemberInfoTests {

    @Test func storageMemberInfoIdentifiable() {
        let info = StorageMemberInfo(id: 1, userId: 5, username: "testuser", accepted: true)
        #expect(info.id == 1)
        #expect(info.userId == 5)
        #expect(info.username == "testuser")
        #expect(info.accepted == true)
    }

    @Test func pendingMemberIsNotAccepted() {
        let info = StorageMemberInfo(id: 2, userId: 6, username: "pending", accepted: false)
        #expect(info.accepted == false)
    }
}

// MARK: - PendingInviteInfo Tests

struct PendingInviteInfoTests {

    @Test func pendingInviteInfoCreation() {
        let invite = PendingInviteInfo(id: 10, storageName: "Office Fridge", storageId: 5, invitedBy: "boss")
        #expect(invite.id == 10)
        #expect(invite.storageName == "Office Fridge")
        #expect(invite.storageId == 5)
        #expect(invite.invitedBy == "boss")
    }
}

// MARK: - LoginResponseDTO Tests

struct LoginResponseDTOTests {

    @Test func loginResponseDecodesCorrectly() throws {
        let json = """
        {"token": "eyJhbGciOiJIUzI1NiJ9.test.signature"}
        """
        let dto = try JSONDecoder().decode(LoginResponseDTO.self, from: Data(json.utf8))
        #expect(dto.token == "eyJhbGciOiJIUzI1NiJ9.test.signature")
    }
}

// MARK: - SignupErrorDTO Tests

struct SignupErrorDTOTests {

    @Test func signupErrorDecodesWithEmailError() throws {
        let json = """
        {"username": null, "email": "Email already taken", "password": null, "passwordRepeat": null, "error": null}
        """
        let dto = try JSONDecoder().decode(SignupErrorDTO.self, from: Data(json.utf8))
        #expect(dto.email == "Email already taken")
        #expect(dto.username == nil)
    }

    @Test func signupErrorDecodesWithAllNull() throws {
        let json = """
        {"username": null, "email": null, "password": null, "passwordRepeat": null, "error": "Unknown error"}
        """
        let dto = try JSONDecoder().decode(SignupErrorDTO.self, from: Data(json.utf8))
        #expect(dto.error == "Unknown error")
    }
}
