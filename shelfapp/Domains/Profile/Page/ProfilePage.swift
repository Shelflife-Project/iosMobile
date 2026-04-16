import SwiftUI
import Observation

@MainActor
@Observable
final class ProfilePageViewModel {
    let appVersion = "1.3.12"
    let appName = "Shelf Life"

    func displayValue(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "N/A"
        }
        return value
    }
}

struct ProfilePage: View {
    @Environment(ProfileStore.self) private var profileContext
    @Environment(AuthStore.self) private var authContext
    @State private var viewModel = ProfilePageViewModel()
    @State private var profileImageRefreshToken = UUID().uuidString
    @State private var animateCrown = true
    @State private var animateLogout = false
    @State private var hasAnimatedLogout = false
    @State private var showEditAccountSheet = false

    private var usernameText: String {
        viewModel.displayValue(profileContext.currentUser?.username)
    }

    private var userPfpURL: URL? {
        guard let userId = profileContext.currentUser?.serverId else {
            return nil
        }
        guard let baseURL = ResourceURLBuilder.userProfilePictureURL(userId: userId) else {
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
                    Button {
                        showEditAccountSheet = true
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

                            Image(systemName: "pencil")
                                .font(.title3)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(height: 48)
                    }
                    .buttonStyle(.plain)
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
            .appGradientBackground()
            .navigationTitle("Profile")
            .onAppear {
                animateCrown = true
                if !hasAnimatedLogout {
                    hasAnimatedLogout = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        animateLogout = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                            animateLogout = false
                        }
                    }
                }
                Task {
                    await profileContext.refreshCurrentUser(authContext: authContext)
                }
            }
            .sheet(isPresented: $showEditAccountSheet) {
                if let user = profileContext.currentUser {
                    EditAccountSheet(
                        user: user,
                        isPresented: $showEditAccountSheet,
                        profileImageRefreshToken: $profileImageRefreshToken
                    )
                }
            }
        }
    }

    private func logout() {
        profileContext.logout(authContext: authContext)
    }
}

#Preview {
    ProfilePage()
}
