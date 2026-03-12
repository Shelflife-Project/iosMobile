//
//  AuthServiceValidationTests.swift
//  shelfappTests
//
//  Tests for AuthService and AuthError input validation logic
//  (no network calls — validates guard clauses).
//

import Testing
import Foundation
@testable import shelfapp

// MARK: - Login Validation

struct AuthServiceLoginValidationTests {

    @Test func loginWithEmptyEmailThrows() async {
        do {
            try await AuthService.shared.login(email: "", password: "password")
            Issue.record("Expected AuthError.invalidInput")
        } catch let error as AuthError {
            #expect(error == .invalidInput)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func loginWithEmptyPasswordThrows() async {
        do {
            try await AuthService.shared.login(email: "test@test.com", password: "")
            Issue.record("Expected AuthError.invalidInput")
        } catch let error as AuthError {
            #expect(error == .invalidInput)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func loginWithBothEmptyThrows() async {
        do {
            try await AuthService.shared.login(email: "", password: "")
            Issue.record("Expected AuthError.invalidInput")
        } catch let error as AuthError {
            #expect(error == .invalidInput)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

// MARK: - Signup Validation

struct AuthServiceSignupValidationTests {

    @Test func signupWithEmptyUsernameThrows() async {
        do {
            try await AuthService.shared.signup(username: "", email: "a@b.com", password: "pass", passwordRepeat: "pass")
            Issue.record("Expected AuthError.invalidInput")
        } catch let error as AuthError {
            #expect(error == .invalidInput)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func signupWithEmptyEmailThrows() async {
        do {
            try await AuthService.shared.signup(username: "user", email: "", password: "pass", passwordRepeat: "pass")
            Issue.record("Expected AuthError.invalidInput")
        } catch let error as AuthError {
            #expect(error == .invalidInput)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func signupWithEmptyPasswordThrows() async {
        do {
            try await AuthService.shared.signup(username: "user", email: "a@b.com", password: "", passwordRepeat: "")
            Issue.record("Expected AuthError.invalidInput")
        } catch let error as AuthError {
            #expect(error == .invalidInput)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func signupWithPasswordMismatchThrows() async {
        do {
            try await AuthService.shared.signup(username: "user", email: "a@b.com", password: "pass1", passwordRepeat: "pass2")
            Issue.record("Expected AuthError.passwordMismatch")
        } catch let error as AuthError {
            #expect(error == .passwordMismatch)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func signupWithInvalidEmailThrows() async {
        do {
            try await AuthService.shared.signup(username: "user", email: "notanemail", password: "pass", passwordRepeat: "pass")
            Issue.record("Expected AuthError.invalidEmail")
        } catch let error as AuthError {
            #expect(error == .invalidEmail)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

// MARK: - Token Management Tests

struct AuthServiceTokenTests {

    @Test func clearTokenRemovesStoredToken() {
        AuthService.shared.saveToken("test-token")
        #expect(AuthService.shared.getStoredToken() == "test-token")

        AuthService.shared.clearToken()
        #expect(AuthService.shared.getStoredToken() == nil)
    }

    @Test func saveAndRetrieveToken() {
        let token = "jwt-token-\(UUID().uuidString)"
        AuthService.shared.saveToken(token)
        #expect(AuthService.shared.getStoredToken() == token)

        // Cleanup
        AuthService.shared.clearToken()
    }

    @Test func fetchCurrentUserWithoutTokenThrows() async {
        // Ensure no token is stored
        AuthService.shared.clearToken()

        do {
            _ = try await AuthService.shared.fetchCurrentUser()
            Issue.record("Expected AuthError.noToken")
        } catch let error as AuthError {
            #expect(error == .noToken)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func logoutClearsTokenAndUser() {
        AuthService.shared.saveToken("some-token")
        AuthService.shared.logout()
        #expect(AuthService.shared.getStoredToken() == nil)
        #expect(AuthService.shared.getStoredUser() == nil)
    }

    @Test func saveAndRetrieveUser() {
        let user = User(username: "testuser", email: "test@test.com", admin: false, serverId: 42)
        AuthService.shared.saveUser(user)

        let retrieved = AuthService.shared.getStoredUser()
        #expect(retrieved?.username == "testuser")
        #expect(retrieved?.email == "test@test.com")
        #expect(retrieved?.serverId == 42)

        // Cleanup
        AuthService.shared.logout()
    }
}

// MARK: - AuthError Equatable Conformance (for test comparisons)

extension AuthError: @retroactive Equatable {
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidInput, .invalidInput),
             (.invalidEmail, .invalidEmail),
             (.passwordMismatch, .passwordMismatch),
             (.invalidCredentials, .invalidCredentials),
             (.noToken, .noToken),
             (.tokenExpired, .tokenExpired):
            return true
        case (.signupError(let a), .signupError(let b)):
            return a.email == b.email && a.username == b.username
        default:
            return false
        }
    }
}
