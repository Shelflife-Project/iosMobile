import SwiftUI

struct NotificationsView: View {
    @Environment(NotificationsContext.self) private var notificationsContext
    @Environment(StorageContext.self) private var storageContext
    @State private var viewModel = NotificationsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if notificationsContext.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notificationsContext.invites.isEmpty && notificationsContext.errorMessage == nil {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        Text("No Notifications")
                            .font(.headline)
                        Text("You're all caught up!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        if !notificationsContext.invites.isEmpty {
                            Section {
                                ForEach(notificationsContext.invites) { invite in
                                    InviteNotificationRow(
                                        invite: invite,
                                        animateEnvelope: viewModel.animateEnvelope,
                                        onAccept: { acceptInvite(invite) },
                                        onDecline: { declineInvite(invite) }
                                    )
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Image(systemName: "envelope.open.fill")
                                        .foregroundStyle(.orange)
                                    Text("Storage Invitations")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .appGradientBackground()
            .navigationTitle("Notifications")
            .alert("Error", isPresented: Binding(
                get: { notificationsContext.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        notificationsContext.errorMessage = nil
                    }
                }
            )) {
                Button("OK") { notificationsContext.errorMessage = nil }
            } message: {
                Text(notificationsContext.errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                Task {
                    await notificationsContext.fetchInvites()
                }
                viewModel.triggerAnimations()
            }
            .refreshable {
                await notificationsContext.refreshInvites()
            }
        }
    }

    private func acceptInvite(_ invite: PendingInviteInfo) {
        Task {
            await notificationsContext.acceptInvite(invite, storageContext: storageContext)
        }
    }

    private func declineInvite(_ invite: PendingInviteInfo) {
        Task {
            await notificationsContext.declineInvite(invite)
        }
    }
}

#Preview {
    NotificationsView()
}
