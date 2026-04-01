//
//  APIServiceTests.swift
//  shelfappTests
//
//  Tests for APIService configuration and error handling.
//

import Testing
import Foundation
@testable import shelfapp

// MARK: - APIHelper Configuration Tests

struct APIHelperConfigTests {

    @Test func defaultBaseURL() {
        let helper = APIHelper.shared
        #expect(helper.baseURL == "http://localhost:8080")
    }

    @Test func configureChangesBaseURL() {
        let helper = APIHelper.shared
        let original = helper.baseURL
        helper.configure(baseURL: "https://api.example.com")
        #expect(helper.baseURL == "https://api.example.com")
        // Restore
        helper.configure(baseURL: original)
    }
}

// MARK: - APIError Tests

struct APIErrorTests {

    @Test func invalidURLErrorDescription() {
        let error = APIError.invalidURL
        #expect(error.errorDescription == "Invalid URL")
    }

    @Test func unauthorizedErrorDescription() {
        let error = APIError.unauthorized
        #expect(error.errorDescription == "Unauthorized - please log in")
    }

    @Test func notFoundErrorDescription() {
        let error = APIError.notFound
        #expect(error.errorDescription == "Resource not found")
    }

    @Test func serverErrorDescription() {
        let error = APIError.serverError(statusCode: 500)
        #expect(error.errorDescription == "Server error: 500")
    }

    @Test func invalidResponseErrorDescription() {
        let error = APIError.invalidResponse
        #expect(error.errorDescription == "Invalid response from server")
    }

    @Test func unknownErrorDescription() {
        let error = APIError.unknown
        #expect(error.errorDescription == "An unknown error occurred")
    }

    @Test func networkErrorWrapsUnderlyingError() {
        let underlying = NSError(domain: "test", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet"])
        let error = APIError.networkError(underlying)
        #expect(error.errorDescription?.contains("No internet") == true)
    }

    @Test func decodingErrorWrapsUnderlyingError() {
        let underlying = NSError(domain: "decode", code: 0, userInfo: [NSLocalizedDescriptionKey: "Type mismatch"])
        let error = APIError.decodingError(underlying)
        #expect(error.errorDescription?.contains("Type mismatch") == true)
    }
}

// MARK: - AuthError Tests

struct AuthErrorTests {

    @Test func invalidInputDescription() {
        let error = AuthError.invalidInput
        #expect(error.errorDescription == "Please fill in all fields")
    }

    @Test func invalidEmailDescription() {
        let error = AuthError.invalidEmail
        #expect(error.errorDescription == "Invalid email address")
    }

    @Test func passwordMismatchDescription() {
        let error = AuthError.passwordMismatch
        #expect(error.errorDescription == "Passwords do not match")
    }

    @Test func invalidCredentialsDescription() {
        let error = AuthError.invalidCredentials
        #expect(error.errorDescription == "Invalid email or password")
    }

    @Test func noTokenDescription() {
        let error = AuthError.noToken
        #expect(error.errorDescription == "Not authenticated")
    }

    @Test func tokenExpiredDescription() {
        let error = AuthError.tokenExpired
        #expect(error.errorDescription == "Your session has expired, please log in again")
    }
}
