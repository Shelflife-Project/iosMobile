import SwiftUI

struct StoragesView: View {
    @Environment(StorageContext.self) private var storageContext
    @Environment(ProfileContext.self) private var profileContext
    @State private var viewModel = StoragesViewModel()

    private var currentUsername: String? {
        profileContext.currentUser?.username
    }

    private var isAdmin: Bool {
        profileContext.currentUser?.admin == true
    }

    private var ownedStorages: [Storage] {
        viewModel.ownedStorages(from: storageContext.storages, currentUsername: currentUsername)
    }

    private var memberStorages: [Storage] {
        viewModel.memberStorages(from: storageContext.storages, currentUsername: currentUsername)
    }

    var body: some View {
        Group {
            if storageContext.storages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)
                        .symbolEffect(.wiggle, isActive: viewModel.animateBox)
                    Text("No Storages")
                        .font(.headline)
                    Text("Create your first storage to get started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(action: { viewModel.showCreateForm = true }) {
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
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    if canEditStorage(storage) {
                                        Button {
                                            viewModel.editingStorage = storage
                                            viewModel.showEditForm = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                    .symbolEffect(.wiggle, isActive: viewModel.animateBox)
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
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    if canEditStorage(storage) {
                                        Button {
                                            viewModel.editingStorage = storage
                                            viewModel.showEditForm = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        } header: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(.blue)
                                    .symbolEffect(.drawOn, isActive: viewModel.animateShared)
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
                Button(action: { viewModel.showCreateForm = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showCreateForm },
            set: { viewModel.showCreateForm = $0 }
        )) {
            CreateStorageSheet(
                isPresented: Binding(
                    get: { viewModel.showCreateForm },
                    set: { viewModel.showCreateForm = $0 }
                ),
                onSave: createStorage
            )
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showEditForm },
            set: { viewModel.showEditForm = $0 }
        )) {
            if let storage = viewModel.editingStorage {
                EditStorageSheet(
                    storage: storage,
                    isPresented: Binding(
                        get: { viewModel.showEditForm },
                        set: { viewModel.showEditForm = $0 }
                    ),
                    onSave: saveStorageEdits
                )
            }
        }
        .alert("Error", isPresented: Binding(
            get: { storageContext.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    storageContext.errorMessage = nil
                }
            }
        )) {
            Button("OK") { storageContext.errorMessage = nil }
        } message: {
            Text(storageContext.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            viewModel.triggerAnimations()
            Task {
                await storageContext.fetch()
            }
        }
    }

    private func createStorage(name: String) {
        Task {
            await storageContext.add(
                name: name,
                currentUser: profileContext.currentUser
            )
        }
    }

    private func deleteStorage(_ storage: Storage) {
        Task {
            await storageContext.delete(storage)
        }
    }

    private func leaveStorage(_ storage: Storage) {
        Task {
            await storageContext.leave(storage)
        }
    }

    private func canEditStorage(_ storage: Storage) -> Bool {
        isAdmin || storage.owner?.username == currentUsername
    }

    private func saveStorageEdits(name: String, runningLowEnabled: Bool, shoppingListEnabled: Bool) {
        guard let storage = viewModel.editingStorage else { return }

        if let storageId = storage.serverId {
            UserDefaults.standard.set(runningLowEnabled, forKey: "storage_\(storageId)_runningLowEnabled")
            UserDefaults.standard.set(shoppingListEnabled, forKey: "storage_\(storageId)_shoppingListEnabled")
        }

        Task {
            await storageContext.updateName(storage, name: name)
        }
    }
}

#Preview {
    StoragesView()
}
