//
//  Product.swift
//  shelfapp
//
//  Created by automation
//

import Foundation
import SwiftData

@Model
final class Product: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var serverId: Int?
    var ownerId: UUID?
    var name: String
    var category: String
    var expirationDaysDelta: Int
    var barcode: String?

    init(name: String, category: String = "", expirationDaysDelta: Int = 0, barcode: String? = nil, ownerId: UUID? = nil, serverId: Int? = nil) {
        self.name = name
        self.category = category
        self.expirationDaysDelta = expirationDaysDelta
        self.barcode = barcode
        self.ownerId = ownerId
        self.serverId = serverId
    }
}
