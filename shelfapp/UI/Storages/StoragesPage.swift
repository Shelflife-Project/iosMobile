import SwiftUI
import Observation
import Lottie

@MainActor
@Observable
final class StoragesPageViewModel {
    var showCreateForm = false
    var showPaginationSettings = false
    var editingStorage: Storage?
    var animateBox = true
    var animateShared = true
    var animateSettings = true
    var searchText = ""
    var debouncedSearchText = ""
    var pageSize = 0
    let pageSizeOptions = [0, 5, 10, 15, 20]
    private var searchDebounceTask: Task<Void, Never>?

    func setSearchText(_ text: String) {
        searchText = text
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                guard !Task.isCancelled else { return }
                debouncedSearchText = text
            } catch {
                return
            }
        }
    }

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
    @Environment(StorageService.self) private var storageContext
    @Environment(ProfileService.self) private var profileContext
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

    private var pageContent: some View {
        storagesList
            .scrollContentBackground(.hidden)
            .navigationTitle("Storages")
            .appGradientBackground()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.showCreateForm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .coloredSheet(isPresented: Binding(
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
            .coloredSheet(item: Binding(
                get: { viewModel.editingStorage },
                set: { viewModel.editingStorage = $0 }
            )) { storage in
                EditStorageSheet(
                    storage: storage,
                    isPresented: Binding(
                        get: { viewModel.editingStorage != nil },
                        set: { isPresented in
                            if !isPresented {
                                viewModel.editingStorage = nil
                            }
                        }
                    ),
                    onSave: { name in
                        saveStorageEdits(storage: storage, name: name)
                    }
                )
            }
            .coloredSheet(isPresented: Binding(
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

                        Section("Pagination") {
                            HStack {
                                Button {
                                    Task { await storageContext.previousPage() }
                                } label: {
                                    Label("Previous", systemImage: "chevron.left")
                                }
                                .buttonStyle(.bordered)
                                .tint(!storageContext.hasPrevious || storageContext.isLoading || viewModel.pageSize == 0 ? .gray : .accentColor)
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
                                .tint(!storageContext.hasNext || storageContext.isLoading || viewModel.pageSize == 0 ? .gray : .accentColor)
                                .disabled(!storageContext.hasNext || storageContext.isLoading || viewModel.pageSize == 0)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .appGradientBackground()
                    .navigationTitle("List Settings")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                viewModel.showPaginationSettings = false
                            }
                            .tint(.accentColor)
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
            .onChange(of: viewModel.debouncedSearchText) { _, search in
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

    var body: some View {
        NavigationStack {
            pageContent
        }
    }

    // MARK: - List Content

    private var storagesList: some View {
        List {
            searchSection

            if storageContext.storages.isEmpty {
                emptyStateSection
            } else {
                if !ownedStorages.isEmpty {
                    ownedStoragesSection
                }

                if !memberStorages.isEmpty {
                    memberStoragesSection
                }
            }
        }
    }

    private var searchSection: some View {
        Section {
            HStack(spacing: 10) {
                TextField("Search storages...", text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.setSearchText($0) }
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
        .listRowBackground(Color.clear)
    }

    private var emptyStateSection: some View {
        Section {
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
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
        }
    }

    private var ownedStoragesSection: some View {
        Section {
            ForEach(ownedStorages) { storage in
                NavigationLink(destination: StorageDetailPage(storage: storage)) {
                    StorageListRow(storage: storage, isOwner: true)
                }
                .trailingSwipeActions {
                    SwipeActionButton(
                        title: "Delete",
                        systemImage: "trash",
                        tint: .red,
                        role: .destructive
                    ) {
                        deleteStorage(storage)
                    }

                    if canEditStorage(storage) {
                        SwipeActionButton(
                            title: "Edit",
                            systemImage: "pencil",
                            tint: .blue
                        ) {
                            viewModel.editingStorage = storage
                        }
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

    private var memberStoragesSection: some View {
        Section {
            ForEach(memberStorages) { storage in
                NavigationLink(destination: StorageDetailPage(storage: storage)) {
                    StorageListRow(storage: storage, isOwner: false)
                }
                .trailingSwipeActions {
                    SwipeActionButton(
                        title: "Leave",
                        systemImage: "rectangle.portrait.and.arrow.right",
                        tint: .orange,
                        role: .destructive
                    ) {
                        leaveStorage(storage)
                    }

                    if canEditStorage(storage) {
                        SwipeActionButton(
                            title: "Edit",
                            systemImage: "pencil",
                            tint: .blue
                        ) {
                            viewModel.editingStorage = storage
                        }
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

private extension StoragesPage {
    func createStorage(name: String) {
        Task {
            await storageContext.add(
                name: name,
                currentUser: profileContext.currentUser
            )
        }
    }

    func deleteStorage(_ storage: Storage) {
        Task {
            await storageContext.delete(storage)
        }
    }

    func leaveStorage(_ storage: Storage) {
        Task {
            await storageContext.leave(storage)
        }
    }

    func canEditStorage(_ storage: Storage) -> Bool {
        isAdmin || storage.owner?.username == currentUsername
    }

    func saveStorageEdits(storage: Storage, name: String) {
        Task {
            await storageContext.updateName(storage, name: name)
        }
    }
}

#Preview {
    StoragesPage()
}


