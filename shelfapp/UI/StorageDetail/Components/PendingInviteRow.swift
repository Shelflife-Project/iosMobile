import SwiftUI

struct PendingInviteRow: View {
    var invite: StorageMemberInfo
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack(alignment: .bottomTrailing) {
                RemoteImage(
                    url: ResourceURLBuilder.userProfilePictureURL(userId: invite.userId),
                    placeholder: "person.circle.fill",
                    size: 36
                )
                Image(systemName: "envelope.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.appAccentWarm)
                    .offset(x: 4, y: 4)
            }

            Text(invite.username)
                .font(AppFont.body())

            Spacer()

            Text("Pending")
                .font(AppFont.caption())
                .foregroundStyle(Color.appAccentWarm)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(Capsule().fill(Color.appAccentWarm.opacity(0.12)))
        }
        .padding(.vertical, Spacing.sm)
        .listCardBackground(accent: .appAccentWarm)
        .trailingSwipeActions {
            SwipeActionButton(
                title: "Cancel",
                systemImage: "xmark.circle",
                tint: .orange,
                role: .destructive
            ) {
                onCancel()
            }
        }
    }
}
