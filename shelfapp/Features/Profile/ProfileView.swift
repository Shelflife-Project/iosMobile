import SwiftUI

struct ProfileView: View {
    @Environment(ProfileContext.self) private var profileContext
    @Environment(AuthContext.self) private var authContext
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    HStack {
                        Text("Username")
                        Spacer()
                        Text(viewModel.displayValue(profileContext.currentUser?.username))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Email")
                        Spacer()
                        Text(viewModel.displayValue(profileContext.currentUser?.email))
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
                        Text(viewModel.appVersion)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("App Name")
                        Spacer()
                        Text(viewModel.appName)
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
            .onAppear {
                Task {
                    await profileContext.refreshCurrentUser(authContext: authContext)
                }
            }
        }
    }

    private func logout() {
        profileContext.logout(authContext: authContext)
    }
}

#Preview {
    ProfileView()
}
