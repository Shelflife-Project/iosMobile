//
//  Storage.swift
//  shelfapp
//
//  Created by automation
//

import Foundation

final class Storage: Identifiable, Hashable {
    var id: UUID = UUID()
    var serverId: Int?
    var name: String
    var owner: User?
    var items: [StorageItem] = []
    var shoppingItems: [ShoppingListItem] = []

    init(name: String, owner: User? = nil, serverId: Int? = nil) {
        self.name = name
        self.owner = owner
        self.serverId = serverId
    }

    static func == (lhs: Storage, rhs: Storage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
