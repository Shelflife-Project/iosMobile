//
//  Storage.swift
//  shelfapp
//
//  Created by automation
//

import Foundation
import SwiftData

@Model
final class Storage: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    @Relationship var owner: User?
    @Relationship var items: [StorageItem] = []
    @Relationship var shoppingItems: [ShoppingListItem] = []

    init(name: String, owner: User? = nil) {
        self.name = name
        self.owner = owner
    }
}
