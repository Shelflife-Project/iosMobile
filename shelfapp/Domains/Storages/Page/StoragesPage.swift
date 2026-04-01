import SwiftUI
import Observation

@MainActor
@Observable
final class StoragesPageViewModel {
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

struct StoragesPage: View {
    @Environment(StorageStore.self) private var storageContext
    @Environment(ProfileStore.self) private var profileContext
    @State private var viewModel = StoragesPageViewModel()

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
                    Section {
                        HStack(spacing: 10) {
                            TextField("Search storages...", text: Binding(
                                get: { viewModel.searchText },
                                set: { viewModel.searchText = $0 }
                            ))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            Button {
                                viewModel.showPaginationSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title3)
                                    .symbolEffect(.pulse, isActive: viewModel.animateSettings)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Pagination settings")
                        }
                    }

                    if !ownedStorages.isEmpty {
                        Section {
                            ForEach(ownedStorages) { storage in
                                NavigationLink(destination: StorageDetailPage(storage: storage)) {
                                    StorageListRow(storage: storage, isOwner: true)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteStorage(storage)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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
                                NavigationLink(destination: StorageDetailPage(storage: storage)) {
                                    StorageListRow(storage: storage, isOwner: false)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        leaveStorage(storage)
                                    } label: {
                                        Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
                                    }
                                    .tint(.orange)
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
        .sheet(isPresented: Binding(
            get: { viewModel.showPaginationSettings },
            set: { viewModel.showPaginationSettings = $0 }
        )) {
            NavigationStack {
                Form {
                    Picker("Page size", selection: Binding(
                        get: { viewModel.pageSize },
                        set: { viewModel.pageSize = $0 }
                    )) {
                        ForEach(viewModel.pageSizeOptions, id: \.self) { size in
                            Text(viewModel.pageSizeLabel(size)).tag(size)
                        }
                    }

                    HStack {
                        Button {
                            Task { await storageContext.previousPage() }
                        } label: {
                            Label("Previous", systemImage: "chevron.left")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!storageContext.hasPrevious || storageContext.isLoading || viewModel.pageSize == 0)

                        Spacer()
                        Text("Page \(storageContext.currentPage + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()

                        Button {
                            Task { await storageContext.nextPage() }
                        } label: {
                            Label("Next", systemImage: "chevron.right")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!storageContext.hasNext || storageContext.isLoading || viewModel.pageSize == 0)
                    }
                }
                .navigationTitle("List Settings")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            viewModel.showPaginationSettings = false
                        }
                    }
                }
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
            viewModel.searchText = storageContext.searchText
            viewModel.pageSize = storageContext.pageSize
            Task {
                await storageContext.fetch(search: viewModel.searchText, page: 0, size: viewModel.pageSize)
            }
        }
        .onChange(of: viewModel.searchText) { _, search in
            Task {
                await storageContext.fetch(search: search, page: 0)
            }
        }
        .onChange(of: viewModel.pageSize) { _, pageSize in
            Task {
                await storageContext.fetch(page: 0, size: pageSize)
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

    private func saveStorageEdits(name: String) {
        guard let storage = viewModel.editingStorage else { return }
        Task {
            await storageContext.updateName(storage, name: name)
        }
    }
}

#Preview {
    StoragesPage()
}
