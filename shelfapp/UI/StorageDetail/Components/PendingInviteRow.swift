import SwiftUI

struct PendingInviteRow: View {
    var invite: StorageMemberInfo
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                RemoteImage(
                    url: ResourceURLBuilder.userProfilePictureURL(userId: invite.userId),
                    placeholder: "person.circle.fill",
                    size: 36
                )

                Image(systemName: "envelope.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                    .offset(x: 4, y: 4)
            }

            Text(invite.username)
                .font(.body)

            Spacer()

            Text("Pending")
                .font(.caption)
                .foregroundStyle(.orange)
        }
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
