import SwiftUI

struct InviteNotificationRow: View {
    var invite: PendingInviteInfo
    var animateEnvelope: Bool
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.badge.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 20))
                .symbolEffect(.drawOn, isActive: animateEnvelope)

            VStack(alignment: .leading, spacing: 4) {
                Text(invite.storageName)
                    .font(.headline)
                Text("Invited by \(invite.invitedBy)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    onAccept()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)

                Button {
                    onDecline()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
