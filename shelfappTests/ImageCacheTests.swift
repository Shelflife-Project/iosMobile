//
//  ImageCacheTests.swift
//  shelfappTests
//
//  Tests for ImageCache and RemoteImage URL helpers.
//

import Testing
import Foundation
import UIKit
@testable import shelfapp

// MARK: - ImageCache Tests

struct ImageCacheTests {

    @Test func cacheStoresAndRetrievesImage() {
        let cache = ImageCache.shared
        let url = URL(string: "https://example.com/test.png")!
        let image = UIImage(systemName: "star")!

        cache.set(image, for: url)
        let retrieved = cache.get(for: url)
        #expect(retrieved != nil)
    }

    @Test func cacheMissReturnsNil() {
        let cache = ImageCache.shared
        let url = URL(string: "https://example.com/nonexistent-\(UUID().uuidString).png")!
        let result = cache.get(for: url)
        #expect(result == nil)
    }

    @Test func cacheDifferentURLsStoreSeparately() {
        let cache = ImageCache.shared
        let url1 = URL(string: "https://example.com/img1-\(UUID().uuidString).png")!
        let url2 = URL(string: "https://example.com/img2-\(UUID().uuidString).png")!

        let image1 = UIImage(systemName: "star.fill")!
        let image2 = UIImage(systemName: "heart.fill")!

        cache.set(image1, for: url1)
        cache.set(image2, for: url2)

        #expect(cache.get(for: url1) != nil)
        #expect(cache.get(for: url2) != nil)
    }

    @Test func cacheOverwritesSameURL() {
        let cache = ImageCache.shared
        let url = URL(string: "https://example.com/overwrite-\(UUID().uuidString).png")!

        let image1 = UIImage(systemName: "star")!
        let image2 = UIImage(systemName: "heart")!

        cache.set(image1, for: url)
        cache.set(image2, for: url)

        let retrieved = cache.get(for: url)
        #expect(retrieved != nil)
    }
}

// MARK: - URL Helper Tests

struct URLHelperTests {

    @Test func productIconURLFormatsCorrectly() {
        let service = APIService.shared
        let original = service.baseURL
        service.configure(baseURL: "http://localhost:8080")

        let url = service.productIconURL(productId: 42)
        #expect(url?.absoluteString == "http://localhost:8080/api/products/42/icon/small")

        service.configure(baseURL: original)
    }

    @Test func userPfpURLFormatsCorrectly() {
        let service = APIService.shared
        let original = service.baseURL
        service.configure(baseURL: "http://localhost:8080")

        let url = service.userPfpURL(userId: 7)
        #expect(url?.absoluteString == "http://localhost:8080/api/users/7/pfp/small")

        service.configure(baseURL: original)
    }

    @Test func normalizeURLHandlesLeadingSlash() {
        let service = APIService.shared
        let original = service.baseURL
        service.configure(baseURL: "http://localhost:8080")

        let url = service.normalizeURL("/api/test")
        #expect(url?.absoluteString == "http://localhost:8080/api/test")

        service.configure(baseURL: original)
    }

    @Test func normalizeURLHandlesTrailingSlashOnBase() {
        let service = APIService.shared
        let original = service.baseURL
        service.configure(baseURL: "http://localhost:8080/")

        let url = service.normalizeURL("api/test")
        #expect(url?.absoluteString == "http://localhost:8080/api/test")

        service.configure(baseURL: original)
    }
}
