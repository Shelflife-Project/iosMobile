import SwiftUI

struct ProfileView: View {
    @Environment(ProfileContext.self) private var profileContext
    @Environment(AuthContext.self) private var authContext
    @State private var viewModel = ProfileViewModel()
    @State private var profileImageRefreshToken = UUID().uuidString
    @State private var animateCrown = true
    @State private var animateLogout = true

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
                    NavigationLink {
                        AccountDetailsView(profileImageRefreshToken: $profileImageRefreshToken)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                RemoteImage(
                                    url: userPfpURL,
                                    placeholder: "person.crop.circle",
                                    size: 36
                                )

                                if profileContext.currentUser?.admin == true {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.yellow)
                                        .padding(3)
                                        .background(Circle().fill(Color(.systemBackground)))
                                        .offset(x: 5, y: 5)
                                        .symbolEffect(.bounce, options: .repeating, value: animateCrown)
                                }
                            }

                            Text(usernameText)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(height: 48)
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
                                .symbolEffect(.drawOn, isActive: animateLogout)
                            Text("Logout")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Profile")
            .onAppear {
                animateCrown = true
                animateLogout = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.6)) { animateLogout = false }
                }
                Task {
                    await profileContext.refreshCurrentUser(authContext: authContext)
                }
            }
        }
        .appGradientBackground()
    }

    private func logout() {
        profileContext.logout(authContext: authContext)
    }
}

#Preview {
    ProfileView()
}
