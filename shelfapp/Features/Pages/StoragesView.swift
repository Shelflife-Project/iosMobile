import SwiftUI
import SwiftData

struct StoragesView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Storage.name) var storages: [Storage]
    @State private var showCreateForm = false
    @State private var newStorageName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Animated icon states
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
                // Try API first — returns a storage with serverId
                _ = try await SyncService.shared.createStorageAndSync(name: name, in: modelContext)
                newStorageName = ""
            } catch {
                // API failed — create locally without serverId
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
                // Same endpoint - backend handles leave vs delete based on role
                try await SyncService.shared.deleteStorageAndSync(storage, in: modelContext)
            } catch {
                errorMessage = "Failed to leave storage: \(error.localizedDescription)"
            }
        }
        modelContext.delete(storage)
    }
}

// MARK: - Storage List Row

struct StorageListRow: View {
    var storage: Storage
    var isOwner: Bool

    @State private var animateIcon = true

    var body: some View {
        HStack(spacing: 12) {
            // Role icon
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(isOwner ? .blue : .purple)
                    .symbolEffect(.drawOn, isActive: animateIcon)

                // Owner crown or member person badge
                if isOwner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.wiggle, isActive: animateIcon)
                        .offset(x: 4, y: 4)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.cyan)
                        .offset(x: 4, y: 4)
                }
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(storage.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 12) {
                    Label(
                        "\(storage.items.count) items",
                        systemImage: "list.bullet"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if !isOwner, let ownerName = storage.owner?.username {
                        Label(ownerName, systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Red badge for toBuy items
            if storage.shoppingItems.count > 0 {
                Text("\(storage.shoppingItems.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.red))
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.5)) { animateIcon = false }
            }
        }
    }
}

// MARK: - Create Storage Sheet

struct CreateStorageSheet: View {
    @Binding var isPresented: Bool
    var onSave: (String) -> Void
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Storage Details") {
                    TextField("Storage Name", text: $name)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Create Storage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    StoragesView()
        .modelContainer(for: [User.self, Storage.self, Product.self, StorageItem.self, ShoppingListItem.self], inMemory: true)
}
