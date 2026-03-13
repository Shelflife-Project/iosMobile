import SwiftUI
import Observation

@MainActor
@Observable
final class StoragesViewModel {
    var showCreateForm = false
    var animateBox = true
    var animateShared = true

    func triggerAnimations() {
        animateBox = true
        animateShared = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateBox = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateShared = false }
        }
    }

    func ownedStorages(from storages: [Storage], currentUsername: String?) -> [Storage] {
        storages.filter { $0.owner?.username == currentUsername }
    }

    func memberStorages(from storages: [Storage], currentUsername: String?) -> [Storage] {
        storages.filter { $0.owner?.username != currentUsername }
    }
}
