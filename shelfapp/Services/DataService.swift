import Foundation
import SwiftData

enum DataService {
    static func seedIfNeeded(in context: ModelContext) {
        let req = FetchDescriptor<Storage>()
        if let existing: [Storage] = try? context.fetch(req), !existing.isEmpty {
            return
        }

        let user = User(username: "you", admin: true)
        let fridge = Storage(name: "Fridge", owner: user)
        let apple = Product(name: "Apple", category: "Fruit", expirationDaysDelta: 10)
        let milk = Product(name: "Milk", category: "Dairy", expirationDaysDelta: 7)
        let si1 = StorageItem(product: apple, expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()))
        let si2 = StorageItem(product: milk, expiresAt: Calendar.current.date(byAdding: .day, value: 5, to: Date()))
        let shop1 = ShoppingListItem(storage: fridge, product: milk, amountToBuy: 2)

        context.insert(user)
        context.insert(apple)
        context.insert(milk)
        context.insert(fridge)
        context.insert(si1)
        context.insert(si2)
        context.insert(shop1)
    }
}
