//
//  AuthManagerTests.swift
//  shelfappTests
//
//  Tests for AuthManager state management.
//

import Testing
import Foundation
@testable import shelfapp

// MARK: - AuthManager Tests

struct AuthManagerTests {

    @Test func sharedInstanceExists() {
        let manager = AuthManager.shared
        #expect(manager != nil)
    }

    @Test func logoutClearsState() {
        let manager = AuthManager.shared
        manager.logout()
        #expect(manager.isAuthenticated == false)
        #expect(manager.currentUser == nil)
        #expect(manager.errorMessage == nil)
    }

    @Test func initialLoadingIsFalse() {
        let manager = AuthManager.shared
        #expect(manager.isLoading == false)
    }
}
