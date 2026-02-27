//
//  APIServiceTests.swift
//  shelfappTests
//
//  Tests for APIService configuration and error handling.
//

import Testing
import Foundation
@testable import shelfapp

// MARK: - APIService Configuration Tests

struct APIServiceConfigTests {

    @Test func defaultBaseURL() {
        let service = APIService.shared
        #expect(service.baseURL == "http://localhost:8080")
    }

    @Test func configureChangesBaseURL() {
        let service = APIService.shared
        let original = service.baseURL
        service.configure(baseURL: "https://api.example.com")
        #expect(service.baseURL == "https://api.example.com")
        // Restore
        service.configure(baseURL: original)
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

    @Test func signupErrorWithEmail() {
        let dto = SignupErrorDTO(username: nil, email: "Email taken", password: nil, passwordRepeat: nil, error: nil)
        let error = AuthError.signupError(dto)
        #expect(error.errorDescription == "Email taken")
    }

    @Test func signupErrorWithUsername() {
        let dto = SignupErrorDTO(username: "Username taken", email: nil, password: nil, passwordRepeat: nil, error: nil)
        let error = AuthError.signupError(dto)
        #expect(error.errorDescription == "Username taken")
    }

    @Test func signupErrorWithPassword() {
        let dto = SignupErrorDTO(username: nil, email: nil, password: "Too short", passwordRepeat: nil, error: nil)
        let error = AuthError.signupError(dto)
        #expect(error.errorDescription == "Too short")
    }

    @Test func signupErrorFallsBackToGenericError() {
        let dto = SignupErrorDTO(username: nil, email: nil, password: nil, passwordRepeat: nil, error: "Something failed")
        let error = AuthError.signupError(dto)
        #expect(error.errorDescription == "Something failed")
    }

    @Test func signupErrorFallsBackToDefault() {
        let dto = SignupErrorDTO(username: nil, email: nil, password: nil, passwordRepeat: nil, error: nil)
        let error = AuthError.signupError(dto)
        #expect(error.errorDescription == "Signup failed")
    }
}
