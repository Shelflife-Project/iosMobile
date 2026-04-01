import Testing
import Foundation
@testable import shelfapp

struct NotificationBadgeTests {

    @Test func badgeCountsInvitesAndUnresolvedRunningLow() {
        let storage = Storage(name: "Fridge", serverId: 10)
        let milk = Product(name: "Milk", serverId: 100)
        let bread = Product(name: "Bread", serverId: 101)

        let runningLowMilk = RunningLowNotification(storage: storage, product: milk, runningLowAt: 3, amount: 1)
        let runningLowBread = RunningLowNotification(storage: storage, product: bread, runningLowAt: 2, amount: 0)

        let shoppingMilk = ShoppingListItem(storage: storage, product: milk, amountToBuy: 2, serverId: 900)

        let invites = [
            PendingInviteInfo(id: 1, storageName: "Pantry", storageId: 11, invitedBy: "alice"),
            PendingInviteInfo(id: 2, storageName: "Garage", storageId: 12, invitedBy: "bob")
        ]

        let count = computeNotificationsBadgeCount(
            invites: invites,
            runningLowItems: [runningLowMilk, runningLowBread],
            shoppingItems: [shoppingMilk]
        )

        #expect(count == 3)
    }

    @Test func badgeExcludesResolvedRunningLowOnly() {
        let storage = Storage(name: "Fridge", serverId: 10)
        let milk = Product(name: "Milk", serverId: 100)

        let runningLowMilk = RunningLowNotification(storage: storage, product: milk, runningLowAt: 3, amount: 1)
        let shoppingMilk = ShoppingListItem(storage: storage, product: milk, amountToBuy: 2, serverId: 901)

        let count = computeNotificationsBadgeCount(
            invites: [],
            runningLowItems: [runningLowMilk],
            shoppingItems: [shoppingMilk]
        )

        #expect(count == 0)
    }
}
