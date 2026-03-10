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
    var serverId: Int?
    @Relationship var product: Product?
    var expiresAt: Date?
    var createdAt: Date

    init(product: Product? = nil, expiresAt: Date? = nil, createdAt: Date = Date(), serverId: Int? = nil) {
        self.product = product
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.serverId = serverId
    }
}
