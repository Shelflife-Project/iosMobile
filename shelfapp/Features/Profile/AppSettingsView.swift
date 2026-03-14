import SwiftUI

struct AppSettingsView: View {
    @State private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
            }

            Section("Display") {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .appGradientBackground()
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
    }
}
