import SwiftUI

struct ProfileView: View {
    @Environment(ProfileContext.self) private var profileContext
    @Environment(AuthContext.self) private var authContext
    @State private var viewModel = ProfileViewModel()

    private var usernameText: String {
        viewModel.displayValue(profileContext.currentUser?.username)
    }

    private var userPfpURL: URL? {
        guard let userId = profileContext.currentUser?.serverId else {
            return nil
        }
        return APIService.shared.userPfpURL(userId: userId)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    HStack {
                        Text("Username")
                        Spacer()
                        HStack(spacing: 6) {
                            if profileContext.currentUser?.admin == true {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                            }
                            Text(usernameText)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text("Profile Picture")
                        Spacer()
                        RemoteImage(
                            url: userPfpURL,
                            placeholder: "person.crop.circle",
                            size: 32
                        )
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
