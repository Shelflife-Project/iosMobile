import SwiftUI

struct AccountDetailsView: View {
    @Environment(ProfileStore.self) private var profileContext
    @Environment(AuthStore.self) private var authContext

    @Binding var profileImageRefreshToken: String
    @State private var showEditSheet = false
    @State private var hasAutoPresented = false

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
        Form {
            Section("Account") {
                HStack(spacing: 12) {
                    RemoteImage(
                        url: userPfpURL,
                        placeholder: "person.crop.circle",
                        size: 48
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(profileContext.currentUser?.username ?? "Unknown User")
                            .font(.headline)
                        Text(profileContext.currentUser?.admin == true ? "Administrator" : "User")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 48)

                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit Account", systemImage: "pencil")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .appGradientBackground()
        .onAppear {
            Task {
                await profileContext.refreshCurrentUser(authContext: authContext)
            }
            if !hasAutoPresented {
                showEditSheet = true
                hasAutoPresented = true
            }
        }
        .coloredSheet(isPresented: $showEditSheet) {
            if let user = profileContext.currentUser {
                EditAccountSheet(
                    user: user,
                    isPresented: $showEditSheet,
                    profileImageRefreshToken: $profileImageRefreshToken
                )
            }
        }
    }
}
