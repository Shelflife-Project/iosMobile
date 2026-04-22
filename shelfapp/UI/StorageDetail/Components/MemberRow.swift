import SwiftUI

struct MemberRow: View {
    var member: StorageMemberInfo
    var isOwnerMember: Bool
    var showRemoveAction: Bool
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                RemoteImage(
                    url: ResourceURLBuilder.userProfilePictureURL(userId: member.userId),
                    placeholder: "person",
                    size: 36
                )

                if isOwnerMember {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                        .offset(x: 4, y: 4)
                }
            }

            Text(member.username)
                .font(.body)

            Spacer()

            if isOwnerMember {
                Text("Owner")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .trailingSwipeActions {
            if showRemoveAction {
                SwipeActionButton(
                    title: "Remove",
                    systemImage: "person.badge.minus",
                    tint: .red,
                    role: .destructive
                ) {
                    onRemove()
                }
            }
        }
    }
}
