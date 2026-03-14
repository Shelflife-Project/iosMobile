import SwiftUI

struct ProfileView: View {
    @Environment(ProfileContext.self) private var profileContext
    @Environment(AuthContext.self) private var authContext
    @State private var viewModel = ProfileViewModel()
    @State private var showEditSheet = false
    @State private var profileImageRefreshToken = UUID().uuidString

    private var usernameText: String {
        viewModel.displayValue(profileContext.currentUser?.username)
    }

    private var userPfpURL: URL? {
        guard let userId = profileContext.currentUser?.serverId else {
            return nil
        }
        guard let baseURL = APIService.shared.userPfpURL(userId: userId) else {
            return nil
        }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "v", value: profileImageRefreshToken)]
        return components?.url
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

                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit Account", systemImage: "pencil")
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
            .sheet(isPresented: $showEditSheet) {
                if let user = profileContext.currentUser {
                    EditAccountSheet(user: user, isPresented: $showEditSheet) {
                        profileImageRefreshToken = UUID().uuidString
                    }
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
