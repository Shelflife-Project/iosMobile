//
//  AppConfigTests.swift
//  shelfappTests
//
//  Tests for AppConfig constants.
//

import Testing
import Foundation
@testable import shelfapp

struct AppConfigTests {

    @Test func baseURLIsNotEmpty() {
        #expect(!AppConfig.baseURL.isEmpty)
    }

    @Test func baseURLStartsWithHTTP() {
        #expect(AppConfig.baseURL.hasPrefix("http"))
    }

    @Test func baseURLIsValidURL() {
        let url = URL(string: AppConfig.baseURL)
        #expect(url != nil)
    }

    @Test func baseURLDefaultsToLocalhost() {
        #expect(AppConfig.baseURL.contains("localhost") || AppConfig.baseURL.contains("127.0.0.1"))
    }
}
