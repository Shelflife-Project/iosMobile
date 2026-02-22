//
//  shelfappApp.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 02. 22..
//

import SwiftUI
import SwiftData

@main
struct shelfappApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Storage.self,
            Product.self,
            StorageItem.self,
            ShoppingListItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(sharedModelContainer)
        }
    }
}
