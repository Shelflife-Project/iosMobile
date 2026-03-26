import SwiftUI

struct StorageDetailView: View {
    @Environment(StorageDetailContext.self) private var storageDetailContext
    @Environment(StorageContext.self) private var storageContext
    @Environment(ShoppingListContext.self) private var shoppingListContext
    @Environment(NotificationsContext.self) private var notificationsContext
    @Environment(ProfileContext.self) private var profileContext
    var storage: Storage
    @State private var viewModel = StorageDetailViewModel()
    @State private var selectedItemForRunningLow: StorageItem? = nil
    @State private var showRunningLowSheet = false

    private var isOwner: Bool {
        viewModel.isOwner(storage: storage, currentUsername: profileContext.currentUser?.username)
    }

    var body: some View {
        List {
            if !storage.items.isEmpty {
                Section {
                    ForEach(storage.items) { item in
                        ItemRow(item: item)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                // Shopping List action
                                let inShoppingList = storage.shoppingItems.contains(where: { $0.product?.serverId == item.product?.serverId })
                                if inShoppingList {
                                    Button {
                                        if let product = item.product {
                                            Task {
                                                await storageDetailContext.removeFromShoppingList(product: product, from: storage)
                                                await refreshSharedContexts()
                                            }
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "cart.badge.minus")
                                    }
                                    .tint(.orange)
                                } else {
                                    Button {
                                        if let product = item.product {
                                            Task {
                                                await storageDetailContext.addToShoppingList(product: product, to: storage)
                                                await refreshSharedContexts()
                                            }
                                        }
                                    } label: {
                                        Label("Add to List", systemImage: "cart.badge.plus")
                                    }
                                    .tint(.green)
                                }

                                // Running Low action
                                Button {
                                    selectedItemForRunningLow = item
                                    showRunningLowSheet = true
                                } label: {
                                    let hasSetting = storage.runningLowSettings.contains(where: { $0.productId == item.product?.serverId })
                                    Label(hasSetting ? "Running Low" : "Set Alert", systemImage: hasSetting ? "bell.fill" : "bell")
                                }
                                .tint(.indigo)
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

            // Members section
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

            // Invited (pending) members section
            if isOwner && !storageDetailContext.invitedMembers.isEmpty {
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

            if storage.items.isEmpty && storageDetailContext.members.isEmpty && !storageDetailContext.isLoadingMembers {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    Text("Empty Storage")
                        .font(.headline)
                    Text("Add items to get started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }
        }
        .scrollContentBackground(.hidden)
        .appGradientBackground()
        .navigationTitle(storage.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { viewModel.showAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    if isOwner {
                        Button(action: { viewModel.showInviteSheet = true }) {
                            Label("Invite Member", systemImage: "person.badge.plus")
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: Binding(
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
        .sheet(isPresented: Binding(
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
        .sheet(isPresented: $showRunningLowSheet, onDismiss: { selectedItemForRunningLow = nil }) {
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
                await storageDetailContext.syncItems(for: storage)
            }
            viewModel.triggerAnimations()
        }
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

    private func refreshSharedContexts() async {
        await storageContext.fetch()
        await shoppingListContext.fetchAggregated()
        await notificationsContext.refreshAll()
    }
}

#Preview {
    StorageDetailView(storage: Storage(name: "Fridge"))
}
