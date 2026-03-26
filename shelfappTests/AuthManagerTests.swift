//
//  AuthManagerTests.swift
//  shelfappTests
//
//  Legacy filename retained; tests now validate current AuthService behavior.
//

import Testing
import Foundation
@testable import shelfapp

struct AuthManagerTests {

    @Test func authServiceSingletonExists() {
        let service = AuthService.shared
        #expect(service.baseURL.isEmpty == false)
    }

    @Test func clearTokenRemovesStoredToken() {
        AuthService.shared.saveToken("test-token")
        #expect(AuthService.shared.getStoredToken() == "test-token")

        AuthService.shared.clearToken()
        #expect(AuthService.shared.getStoredToken() == nil)
    }
}
