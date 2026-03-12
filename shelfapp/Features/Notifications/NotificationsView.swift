import SwiftUI
import SwiftData

struct NotificationsView: View {
    @Environment(\.modelContext) var modelContext
    @State private var invites: [PendingInviteInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var animateEnvelope = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if invites.isEmpty && errorMessage == nil {
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
                        if !invites.isEmpty {
                            Section {
                                ForEach(invites) { invite in
                                    InviteNotificationRow(
                                        invite: invite,
                                        animateEnvelope: animateEnvelope,
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
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                loadInvites()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.6)) { animateEnvelope = false }
                }
            }
            .refreshable {
                await refreshInvites()
            }
        }
    }

    private func loadInvites() {
        isLoading = true
        Task {
            do {
                let fetched = try await APIService.shared.fetchPendingInvites()
                await MainActor.run {
                    invites = fetched
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Failed to fetch invites: \(error.localizedDescription)")
            }
        }
    }

    private func refreshInvites() async {
        do {
            let fetched = try await APIService.shared.fetchPendingInvites()
            await MainActor.run {
                invites = fetched
            }
        } catch {
            print("Failed to refresh invites: \(error.localizedDescription)")
        }
    }

    private func acceptInvite(_ invite: PendingInviteInfo) {
        Task {
            do {
                try await APIService.shared.acceptInvite(inviteId: invite.id)
                try? await SyncService.shared.syncStorages(in: modelContext)
                await MainActor.run {
                    withAnimation { invites.removeAll { $0.id == invite.id } }
                }
            } catch {
                errorMessage = "Failed to accept invite: \(error.localizedDescription)"
            }
        }
    }

    private func declineInvite(_ invite: PendingInviteInfo) {
        Task {
            do {
                try await APIService.shared.declineInvite(inviteId: invite.id)
                await MainActor.run {
                    withAnimation { invites.removeAll { $0.id == invite.id } }
                }
            } catch {
                errorMessage = "Failed to decline invite: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    NotificationsView()
}
