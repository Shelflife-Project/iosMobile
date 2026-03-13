import Foundation
import Observation
import SwiftData

@MainActor
@Observable
class NotificationsContext {
    var invites: [PendingInviteInfo] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func fetchInvites() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            invites = try await apiService.fetchPendingInvites()
        } catch {
            errorMessage = "Failed to fetch invites: \(error.localizedDescription)"
        }
    }

    func refreshInvites() async {
        do {
            invites = try await apiService.fetchPendingInvites()
        } catch {
            errorMessage = "Failed to refresh invites: \(error.localizedDescription)"
        }
    }

    func acceptInvite(_ invite: PendingInviteInfo, modelContext: ModelContext, storageContext: StorageContext) async {
        errorMessage = nil

        do {
            try await apiService.acceptInvite(inviteId: invite.id)
            invites.removeAll { $0.id == invite.id }
            await storageContext.fetch(context: modelContext)
        } catch {
            errorMessage = "Failed to accept invite: \(error.localizedDescription)"
        }
    }

    func declineInvite(_ invite: PendingInviteInfo) async {
        errorMessage = nil

        do {
            try await apiService.declineInvite(inviteId: invite.id)
            invites.removeAll { $0.id == invite.id }
        } catch {
            errorMessage = "Failed to decline invite: \(error.localizedDescription)"
        }
    }
}
