import SwiftUI
import SwiftData

struct StoragesView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Storage.name) var storages: [Storage]
    @State private var showCreateForm = false
    @State private var newStorageName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if storages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
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
                        ForEach(storages) { storage in
                            NavigationLink(destination: StorageDetailView(storage: storage)) {
                                StorageListRow(storage: storage)
                            }
                        }
                        .onDelete { offsets in
                            deleteStorages(offsets: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Storages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !storages.isEmpty {
                        EditButton()
                    }
                }
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
        }
    }

    private func createStorage(name: String) {
        isLoading = true
        Task {
            do {
                // Try to sync with API first
                let localStorage = Storage(name: name)
                modelContext.insert(localStorage)
                try modelContext.save()
                newStorageName = ""
                isLoading = false

                // Attempt API sync in background
                Task {
                    do {
                        _ = try await SyncService.shared.createStorageAndSync(name: name, in: modelContext)
                    } catch {
                        print("API sync failed (local storage created): \(error.localizedDescription)")
                    }
                }
            } catch {
                errorMessage = "Failed to create storage: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func deleteStorages(offsets: IndexSet) {
        for index in offsets {
            let storage = storages[index]
            Task {
                do {
                    try await SyncService.shared.deleteStorageAndSync(storage, in: modelContext)
                } catch {
                    errorMessage = "Failed to delete storage: \(error.localizedDescription)"
                }
            }
            modelContext.delete(storage)
        }
    }
}

struct StorageListRow: View {
    var storage: Storage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(storage.name)
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                Label(
                    "\(storage.items.count) items",
                    systemImage: "list.bullet"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Label(
                    "\(storage.shoppingItems.count) to buy",
                    systemImage: "cart"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

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
