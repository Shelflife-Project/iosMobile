import SwiftUI
import SwiftData

struct StoragesView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Storage.name) var storages: [Storage]
    @State private var showCreateForm = false
    @State private var newStorageName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var animateBox = true
    @State private var animateShared = true

    private var currentUsername: String? {
        AuthManager.shared.currentUser?.username
    }

    private var ownedStorages: [Storage] {
        storages.filter { $0.owner?.username == currentUsername }
    }

    private var memberStorages: [Storage] {
        storages.filter { $0.owner?.username != currentUsername }
    }

    var body: some View {
        Group {
            if storages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)
                        .symbolEffect(.wiggle, isActive: animateBox)
                    Text("No Storages")
                        .font(.headline)
                    Text("Create your first storage to get started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(action: { showCreateForm = true }) {
                        Label("Create Storage", systemImage: "plus.circle.fill")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List {
                    if !ownedStorages.isEmpty {
                        Section {
                            ForEach(ownedStorages) { storage in
                                NavigationLink(destination: StorageDetailView(storage: storage)) {
                                    StorageListRow(storage: storage, isOwner: true)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteStorage(storage)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                    .symbolEffect(.wiggle, isActive: animateBox)
                                Text("My Storages")
                            }
                        }
                    }

                    if !memberStorages.isEmpty {
                        Section {
                            ForEach(memberStorages) { storage in
                                NavigationLink(destination: StorageDetailView(storage: storage)) {
                                    StorageListRow(storage: storage, isOwner: false)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        leaveStorage(storage)
                                    } label: {
                                        Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
                                    }
                                    .tint(.orange)
                                }
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(.blue)
                                    .symbolEffect(.drawOn, isActive: animateShared)
                                Text("Shared with Me")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .shadow(radius: 4, x: 3, y: 3)
            }
        }
        .navigationTitle("Storages")
        .appGradientBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showCreateForm = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateForm) {
            CreateStorageSheet(
                isPresented: $showCreateForm,
                onSave: createStorage
            )
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            triggerAnimations()
        }
    }

    private func triggerAnimations() {
        animateBox = true
        animateShared = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) { animateBox = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) { animateShared = false }
        }
    }

    private func createStorage(name: String) {
        isLoading = true
        Task {
            do {
                _ = try await SyncService.shared.createStorageAndSync(name: name, in: modelContext)
                newStorageName = ""
            } catch {
                do {
                    let localStorage = Storage(name: name, owner: AuthManager.shared.currentUser)
                    modelContext.insert(localStorage)
                    try modelContext.save()
                    newStorageName = ""
                    print("API failed, created storage locally: \(error.localizedDescription)")
                } catch {
                    errorMessage = "Failed to create storage: \(error.localizedDescription)"
                }
            }
            isLoading = false
        }
    }

    private func deleteStorage(_ storage: Storage) {
        Task {
            do {
                try await SyncService.shared.deleteStorageAndSync(storage, in: modelContext)
            } catch {
                errorMessage = "Failed to delete storage: \(error.localizedDescription)"
            }
        }
        modelContext.delete(storage)
    }

    private func leaveStorage(_ storage: Storage) {
        Task {
            do {
                try await SyncService.shared.deleteStorageAndSync(storage, in: modelContext)
            } catch {
                errorMessage = "Failed to leave storage: \(error.localizedDescription)"
            }
        }
        modelContext.delete(storage)
    }
}

#Preview {
    StoragesView()
        .modelContainer(for: [User.self, Storage.self, Product.self, StorageItem.self, ShoppingListItem.self], inMemory: true)
}
