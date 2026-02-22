//
//  StorageItem.swift
//  shelfapp
//
//  Created by automation
//

import Foundation
import SwiftData

@Model
final class StorageItem: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    @Relationship var product: Product?
    var expiresAt: Date?
    var createdAt: Date

    init(product: Product? = nil, expiresAt: Date? = nil, createdAt: Date = Date()) {
        self.product = product
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }
}
