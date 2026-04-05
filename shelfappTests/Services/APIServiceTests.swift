//
//  APIServiceTests.swift
//  shelfappTests
//
//  Tests for APIService configuration and error handling.
//

import Testing
import Foundation
@testable import shelfapp

// MARK: - AppConfig Tests

struct AppConfigTests {
    @Test func defaultBaseURL() {
        #expect(AppConfig.baseURL == "http://localhost:8080")
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

