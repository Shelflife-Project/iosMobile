//
//  Product.swift
//  shelfapp
//
//  Created by automation
//

import Foundation

final class Product: Identifiable, Hashable {
    var id: UUID = UUID()
    var serverId: Int?
    var ownerId: Int?
    var name: String
    var category: String
    var expirationDaysDelta: Int
    var barcode: String?

    init(name: String, category: String = "", expirationDaysDelta: Int = 0, barcode: String? = nil, ownerId: Int? = nil, serverId: Int? = nil) {
        self.name = name
        self.category = category
        self.expirationDaysDelta = expirationDaysDelta
        self.barcode = barcode
        self.ownerId = ownerId
        self.serverId = serverId
    }

    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
