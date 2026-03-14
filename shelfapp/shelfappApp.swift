//
//  shelfappApp.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 02. 22..
//

import SwiftUI

@main
struct shelfappApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
        }
    }
}
