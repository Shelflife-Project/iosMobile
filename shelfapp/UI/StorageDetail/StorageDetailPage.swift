import SwiftUI
import Observation

@MainActor
@Observable
final class StorageDetailPageViewModel {
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

struct StorageDetailPage: View {
    @Environment(ProductService.self) private var productsContext
    @Environment(StorageDetailService.self) private var storageDetailContext
    @Environment(StorageService.self) private var storageContext
    @Environment(ShoppingListService.self) private var shoppingListContext
    @Environment(NotificationsService.self) private var notificationsContext
    @Environment(ProfileService.self) private var profileContext
    var storage: Storage
    @State private var viewModel = StorageDetailPageViewModel()
    @State private var selectedItemForRunningLow: StorageItem? = nil
    @State private var showRunningLowSheet = false
    @State private var showEditStorage = false

    private var isOwner: Bool {
        viewModel.isOwner(storage: storage, currentUsername: profileContext.currentUser?.username)
    }

    var body: some View {
        VStack(spacing: 0) {
            storageHeaderCard
                .padding(.horizontal, Spacing.base)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.md)
            detailList
        }
        .scrollContentBackground(.hidden)
        .appGradientBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        Task { await prepareAddItemSheet() }
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    if isOwner {
                        Button(action: { viewModel.showInviteSheet = true }) {
                            Label("Invite Member", systemImage: "person.badge.plus")
                        }
                        Button(action: { showEditStorage = true }) {
                            Label("Edit Storage", systemImage: "pencil")
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .coloredSheet(isPresented: Binding(
            get: { viewModel.showAddItem },
            set: { viewModel.showAddItem = $0 }
        )) {
            AddItemSheet(
                storage: storage,
                isPresented: Binding(
                    get: { viewModel.showAddItem },
                    set: { viewModel.showAddItem = $0 }
                ),
                onAdded: {
                    Task {
                        await refreshSharedContexts()
                    }
                }
            )
        }
        .coloredSheet(isPresented: Binding(
            get: { viewModel.showInviteSheet },
            set: { viewModel.showInviteSheet = $0 }
        )) {
            InviteMemberSheet(
                isPresented: Binding(
                    get: { viewModel.showInviteSheet },
                    set: { viewModel.showInviteSheet = $0 }
                ),
                onInvite: { email in inviteMember(email: email) }
            )
        }
        .coloredSheet(isPresented: $showRunningLowSheet, onDismiss: { selectedItemForRunningLow = nil }) {
            if let item = selectedItemForRunningLow, let product = item.product {
                let existingSetting = storage.runningLowSettings.first(where: { $0.productId == product.serverId })
                SetRunningLowSheet(
                    product: product,
                    existingSetting: existingSetting,
                    isPresented: $showRunningLowSheet,
                    onSave: { threshold in
                        Task { await storageDetailContext.setRunningLow(product: product, in: storage, threshold: threshold) }
                    },
                    onRemove: {
                        Task { await storageDetailContext.removeRunningLow(product: product, from: storage) }
                    }
                )
            }
        }
        .coloredSheet(isPresented: $showEditStorage) {
            EditStorageSheet(
                storage: storage,
                isPresented: $showEditStorage,
                onSave: saveStorageEdits
            )
        }
        .alert("Error", isPresented: Binding(
            get: { storageDetailContext.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    storageDetailContext.errorMessage = nil
                }
            }
        )) {
            Button("OK") { storageDetailContext.errorMessage = nil }
        } message: {
            Text(storageDetailContext.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            Task {
                await storageDetailContext.fetchMembers(for: storage)
                await storageDetailContext.loadItems(for: storage)
            }
            viewModel.triggerAnimations()
        }
    }

    // MARK: - Sections

    private var storageHeaderCard: some View {
        AppCard(style: .prominent) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(storage.name)
                        .font(AppFont.headline())
                    if let owner = storage.owner {
                        Text("by \(owner.username)")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.appSecondaryLabel)
                    }
                }
                Spacer()
            }
        }
    }

    private var detailList: some View {
        List {
            // Inventory items in this storage.
            if !storage.items.isEmpty {
                itemsSection
            }

            // Members and ownership management.
            membersSection

            if isOwner && !storageDetailContext.invitedMembers.isEmpty {
                invitedMembersSection
            }

            if storage.items.isEmpty && storageDetailContext.members.isEmpty && !storageDetailContext.isLoadingMembers {
                emptyStateRow
            }
        }
    }

    private var itemsSection: some View {
        Section {
            ForEach(storage.items) { item in
                ItemRow(item: item)
                    .trailingSwipeActions {
                        itemSwipeActions(for: item)
                    }
            }
            .onDelete { offsets in
                deleteItems(offsets: offsets)
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(.blue)
                    .symbolEffect(.drawOn, isActive: viewModel.animateItems)
                Text("Items in Storage")
            }
        }
    }

    @ViewBuilder
    private func itemSwipeActions(for item: StorageItem) -> some View {
        SwipeActionButton(
            title: "Delete",
            systemImage: "trash",
            tint: .red,
            role: .destructive
        ) {
            deleteItem(item)
        }

        let inShoppingList = storage.shoppingItems.contains(where: { $0.product?.serverId == item.product?.serverId })
        SwipeActionButton(
            title: inShoppingList ? "In List" : "Add to List",
            systemImage: inShoppingList ? "cart.fill" : "cart.badge.plus",
            tint: inShoppingList ? .gray : .green
        ) {
            guard !inShoppingList, let product = item.product else { return }
            Task {
                await storageDetailContext.addToShoppingList(product: product, to: storage)
                await refreshSharedContexts()
            }
        }
        .disabled(inShoppingList)

        SwipeActionButton(
            title: runningLowLabel(for: item),
            systemImage: runningLowSymbol(for: item),
            tint: .indigo
        ) {
            selectedItemForRunningLow = item
            showRunningLowSheet = true
        }
    }

    private var membersSection: some View {
        Section {
            if storageDetailContext.isLoadingMembers {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if storageDetailContext.acceptedMembers.isEmpty {
                Text("No members")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(storageDetailContext.acceptedMembers) { member in
                    MemberRow(
                        member: member,
                        isOwnerMember: isOwnerMember(member),
                        showRemoveAction: isOwner && !isOwnerMember(member),
                        onRemove: { removeMember(member) }
                    )
                }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.purple)
                    .symbolEffect(.drawOn, isActive: viewModel.animateItems)
                Text("Members")
            }
        }
    }

    private var invitedMembersSection: some View {
        Section {
            ForEach(storageDetailContext.invitedMembers) { invite in
                PendingInviteRow(
                    invite: invite,
                    onCancel: { cancelInvite(invite) }
                )
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "envelope.badge.person.crop")
                    .foregroundStyle(.orange)
                Text("Invited")
            }
        }
    }

    private var emptyStateRow: some View {
        VStack(alignment: .center, spacing: Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(Color.appSecondaryLabel)
            Text("Empty Storage")
                .font(AppFont.headline())
            Text("Add items to get started")
                .font(AppFont.caption())
                .foregroundStyle(Color.appSecondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: - Helpers

    private func isOwnerMember(_ member: StorageMemberInfo) -> Bool {
        member.userId == storage.owner?.serverId
    }

    private func removeMember(_ member: StorageMemberInfo) {
        Task {
            await storageDetailContext.removeMember(member, from: storage)
        }
    }

    private func inviteMember(email: String) {
        Task {
            await storageDetailContext.inviteMember(email: email, to: storage)
        }
    }

    private func cancelInvite(_ invite: StorageMemberInfo) {
        Task {
            await storageDetailContext.cancelInvite(invite, from: storage)
        }
    }

    private func saveStorageEdits(name: String) {
        Task {
            await storageContext.updateName(storage, name: name)
        }
    }

    @MainActor
    private func prepareAddItemSheet() async {
        if productsContext.products.isEmpty && !productsContext.isLoading {
            await productsContext.fetch()
        }
        viewModel.showAddItem = true
    }

    // MARK: - Item Deletion

    private func deleteItems(offsets: IndexSet) {
        Task {
            await storageDetailContext.deleteItems(at: offsets, from: storage)
        }
    }

    private func deleteItem(_ item: StorageItem) {
        Task {
            await storageDetailContext.deleteItem(item, from: storage)
            await refreshSharedContexts()
        }
    }

    private func runningLowLabel(for item: StorageItem) -> String {
        let hasSetting = storage.runningLowSettings.contains(where: { $0.productId == item.product?.serverId })
        return hasSetting ? "Running Low" : "Set Alert"
    }

    private func runningLowSymbol(for item: StorageItem) -> String {
        let hasSetting = storage.runningLowSettings.contains(where: { $0.productId == item.product?.serverId })
        return hasSetting ? "bell.fill" : "bell"
    }

    private func refreshSharedContexts() async {
        await storageContext.fetch()
        await shoppingListContext.fetchAggregated()
        await notificationsContext.refreshAll()
    }
}

#Preview {
    let mockStorageDTO = StorageDTO(id: 1, name: "Fridge", owner: UserDTO(id: 1, email: "test@example.com", username: "Test", admin: false), items: nil, members: nil)
    let mockStorage = Storage(from: mockStorageDTO)
    StorageDetailPage(storage: mockStorage)
}
