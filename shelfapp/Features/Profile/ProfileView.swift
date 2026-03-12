import SwiftUI

struct ProfileView: View {
    @State private var authManager = AuthManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(authManager.currentUser?.username ?? "N/A")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.currentUser?.email ?? "N/A")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Settings") {
                    NavigationLink(destination: AppSettingsView()) {
                        HStack {
                            Image(systemName: "gear")
                            Text("App Settings")
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("Shelf Life")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        logout()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("Logout")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private func logout() {
        authManager.logout()
    }
}

#Preview {
    ProfileView()
}
