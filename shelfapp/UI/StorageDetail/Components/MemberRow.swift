import SwiftUI

struct MemberRow: View {
    var member: StorageMemberInfo
    var isOwnerMember: Bool
    var showRemoveAction: Bool
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
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
                .font(AppFont.body())

            Spacer()

            if isOwnerMember {
                Text("Owner")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appSecondaryLabel)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Capsule().fill(Color.appPrimary.opacity(0.12)))
            }
        }
        .padding(.vertical, Spacing.sm)
        .listCardBackground(accent: .appPrimary)
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
