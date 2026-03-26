import SwiftUI
import Observation

@MainActor
@Observable
final class StoragesViewModel {
    var showCreateForm = false
    var showEditForm = false
    var showPaginationSettings = false
    var editingStorage: Storage?
    var animateBox = true
    var animateShared = true
    var animateSettings = true
    var searchText = ""
    var pageSize = 0
    let pageSizeOptions = [0, 5, 10, 15, 20]

    func triggerAnimations() {
        animateBox = true
        animateShared = true
        animateSettings = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateBox = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateShared = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateSettings = false }
        }
    }

    func pageSizeLabel(_ value: Int) -> String {
        value == 0 ? "All" : "\(value)"
    }

    func ownedStorages(from storages: [Storage], currentUsername: String?) -> [Storage] {
        storages.filter { $0.owner?.username == currentUsername }
    }

    func memberStorages(from storages: [Storage], currentUsername: String?) -> [Storage] {
        storages.filter { $0.owner?.username != currentUsername }
    }
}
