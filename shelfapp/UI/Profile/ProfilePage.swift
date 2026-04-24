import SwiftUI
import Observation

@MainActor
@Observable
final class ProfilePageViewModel {
    let appVersion = "1.3.12"
    let appName = "Shelf Life"

    func displayValue(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "N/A" }
        return value
    }
}

struct ProfilePage: View {
    @Environment(ProfileService.self) private var profileContext
    @Environment(AuthService.self) private var authContext
    @AppStorage("pushNotificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    @State private var viewModel = ProfilePageViewModel()
    @State private var profileImageRefreshToken = UUID().uuidString
    @State private var animateCrown = true
    @State private var showEditAccountSheet = false

    private var usernameText: String {
        viewModel.displayValue(profileContext.currentUser?.username)
    }

    private var emailText: String {
        viewModel.displayValue(profileContext.currentUser?.email)
    }

    private var userPfpURL: URL? {
        guard let userId = profileContext.currentUser?.serverId else { return nil }
        guard let baseURL = ResourceURLBuilder.userProfilePictureURL(userId: userId) else { return nil }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "v", value: profileImageRefreshToken)]
        return components?.url
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    profileHeader
                    settingsSections
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.lg)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Profile")
            .appGradientBackground()
            .onAppear {
                animateCrown = true
                Task { await profileContext.refreshCurrentUser() }
            }
            .coloredSheet(isPresented: $showEditAccountSheet) {
                if let user = profileContext.currentUser {
                    EditAccountSheet(
                        user: user,
                        isPresented: $showEditAccountSheet,
                        profileImageRefreshToken: $profileImageRefreshToken
                    )
                }
            }
            .onChange(of: notificationsEnabled) { _, isEnabled in
                if isEnabled {
                    Task { await LocalNotificationService.shared.requestAuthorizationIfNeeded() }
                }
            }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: Spacing.md) {
            ZStack(alignment: .bottomTrailing) {
                RemoteImage(url: userPfpURL, placeholder: "person.crop.circle", size: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.appPrimary.opacity(0.3), lineWidth: 2))

                if profileContext.currentUser?.admin == true {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.yellow)
                        .padding(4)
                        .background(Circle().fill(Color.appSurface))
                        .offset(x: 4, y: 4)
                        .symbolEffect(.bounce, options: .repeating, value: animateCrown)
                }
            }

            VStack(spacing: Spacing.xxs) {
                Text(usernameText)
                    .font(AppFont.title3())

                if profileContext.currentUser?.email != nil {
                    Text(emailText)
                        .font(AppFont.footnote())
                        .foregroundStyle(Color.appSecondaryLabel)
                }
            }

            Button("Edit Profile") { showEditAccountSheet = true }
                .buttonStyle(.soft(tint: .appPrimary))
                .frame(maxWidth: 180)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.appCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(Color.appPrimary.opacity(0.4), lineWidth: BorderWidth.regular)
        )
        .appShadow()
    }

    // MARK: - Settings sections

    private var settingsSections: some View {
        VStack(spacing: Spacing.md) {
            settingsCard(title: "Notifications", icon: "bell.fill", iconColor: .appAccentWarm) {
                settingsToggleRow(
                    label: "Push Notifications",
                    icon: "bell.badge",
                    isOn: $notificationsEnabled
                )
            }

            settingsCard(title: "Display", icon: "paintbrush.fill", iconColor: .appPrimary) {
                settingsToggleRow(
                    label: "Dark Mode",
                    icon: "moon.fill",
                    isOn: $darkModeEnabled
                )
            }

            settingsCard(title: "About", icon: "info.circle.fill", iconColor: .appAccentFresh) {
                settingsInfoRow(label: "Version", value: viewModel.appVersion)
                Divider().padding(.leading, Spacing.xxxl)
                settingsInfoRow(label: "App", value: viewModel.appName)
            }

            Button(role: .destructive) { logout() } label: {
                Label("Sign Out", systemImage: "arrow.right.circle.fill")
                    .font(AppFont.bodyEmphasized())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.destructive)
            .padding(.top, Spacing.sm)
        }
    }

    // MARK: - Reusable row builders

    private func settingsCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder rows: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(AppFont.footnote())
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appSecondaryLabel)
            }
            .padding(.horizontal, Spacing.base)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xs)

            rows()
        }
        .background(Color.appCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .stroke(Color.appBorder, lineWidth: BorderWidth.regular)
        )
        .appShadow(radius: 8, y: 3, opacity: 0.06)
    }

    private func settingsToggleRow(label: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.appSecondaryLabel)
                .frame(width: 24)
            Text(label)
                .font(AppFont.body())
            Spacer()
            Toggle("", isOn: isOn).labelsHidden()
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
    }

    private func settingsInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFont.body())
            Spacer()
            Text(value)
                .font(AppFont.body())
                .foregroundStyle(Color.appSecondaryLabel)
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Actions

    private func logout() {
        profileContext.logout()
    }
}

#Preview {
    ProfilePage()
}
