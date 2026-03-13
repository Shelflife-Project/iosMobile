//
//  ShoppingListItem.swift
//  shelfapp
//
//  Created by automation
//

import Foundation

final class ShoppingListItem: Identifiable, Hashable {
    var id: UUID = UUID()
    var serverId: Int?
    var storage: Storage?
    var product: Product?
    var amountToBuy: Int = 1

    init(storage: Storage? = nil, product: Product? = nil, amountToBuy: Int = 1, serverId: Int? = nil) {
        self.storage = storage
        self.product = product
        self.amountToBuy = amountToBuy
        self.serverId = serverId
    }

    static func == (lhs: ShoppingListItem, rhs: ShoppingListItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

