import SwiftUI
import Observation

@MainActor
@Observable
final class StorageDetailViewModel {
    var showAddItem = false
    var showInviteSheet = false
    var animateItems = true
    var contentRefreshID = UUID()

    func triggerAnimations() {
        animateItems = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateItems = false }
        }
    }

    func isOwner(storage: Storage, currentUsername: String?) -> Bool {
        storage.owner?.username == currentUsername
    }

    func refreshContent() {
        contentRefreshID = UUID()
    }
}
