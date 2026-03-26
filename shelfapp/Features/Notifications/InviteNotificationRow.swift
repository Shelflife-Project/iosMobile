import SwiftUI

struct InviteNotificationRow: View {
    var invite: PendingInviteInfo
    var animateEnvelope: Bool
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
            }

            HStack(spacing: 10) {
                Button {
                    onAccept()
                } label: {
                    Label("Accept", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    onDecline()
                } label: {
                    Label("Decline", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.75))
        )
    }
}
