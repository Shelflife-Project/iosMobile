//
//  StorageItem.swift
//  shelfapp
//
//  Created by automation
//

import Foundation

final class StorageItem: Identifiable, Hashable {
    var id: UUID = UUID()
    var serverId: Int?
    var product: Product?
    var expiresAt: Date?
    var createdAt: Date

    init(product: Product? = nil, expiresAt: Date? = nil, createdAt: Date = Date(), serverId: Int? = nil) {
        self.product = product
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.serverId = serverId
    }

    static func == (lhs: StorageItem, rhs: StorageItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
