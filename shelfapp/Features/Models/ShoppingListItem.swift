//
//  ShoppingListItem.swift
//  shelfapp
//
//  Created by automation
//

import Foundation
import SwiftData

@Model
final class ShoppingListItem: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    @Relationship var storage: Storage?
    @Relationship var product: Product?
    var amountToBuy: Int = 1

    init(storage: Storage? = nil, product: Product? = nil, amountToBuy: Int = 1) {
        self.storage = storage
        self.product = product
        self.amountToBuy = amountToBuy
    }
}
