import SwiftUI
import SwiftData

struct StorageDetailView: View {
    @Environment(\.modelContext) var modelContext
    var storage: Storage
    @State private var showAddItem = false
    @State private var showInviteSheet = false
    @State private var errorMessage: String?
    @State private var members: [StorageMemberInfo] = []
    @State private var pendingInvites: [StorageMemberInfo] = []
    @State private var isLoadingMembers = false
    @State private var animateItems = true

    private var isOwner: Bool {
        storage.owner?.username == AuthManager.shared.currentUser?.username
    }

    private var acceptedMembers: [StorageMemberInfo] {
        members.filter { $0.accepted }
    }

    private var invitedMembers: [StorageMemberInfo] {
        members.filter { !$0.accepted }
    }

    var body: some View {
        List {
            if !storage.items.isEmpty {
                Section {
                    ForEach(storage.items) { item in
                        ItemRow(item: item)
                    }
                    .onDelete { offsets in
                        deleteItems(offsets: offsets)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.full.fill")
                            .foregroundStyle(.blue)
                            .symbolEffect(.drawOn, isActive: animateItems)
                        Text("Items in Storage")
                    }
                }
            }

            if !storage.shoppingItems.isEmpty {
                Section {
                    ForEach(storage.shoppingItems) { item in
                        ShoppingItemRow(item: item)
                    }
                    .onDelete { offsets in
                        deleteShoppingItems(offsets: offsets)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "cart.fill")
                            .foregroundStyle(.orange)
                            .symbolEffect(.drawOn, isActive: animateItems)
                        Text("Shopping List")
                    }
                }
            }

            // Members section
            Section {
                if isLoadingMembers {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if acceptedMembers.isEmpty {
                    Text("No members")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(acceptedMembers) { member in
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
                        .symbolEffect(.drawOn, isActive: animateItems)
                    Text("Members")
                }
            }

            // Invited (pending) members section
            if isOwner && !invitedMembers.isEmpty {
                Section {
                    ForEach(invitedMembers) { invite in
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

            if storage.items.isEmpty && storage.shoppingItems.isEmpty && members.isEmpty && !isLoadingMembers {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundStyle(.gray)
                    Text("Empty Storage")
                        .font(.headline)
                    Text("Add items or shopping list items to get started")
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
                if !storage.items.isEmpty {
                    EditButton()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showAddItem = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    if isOwner {
                        Button(action: { showInviteSheet = true }) {
                            Label("Invite Member", systemImage: "person.badge.plus")
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemSheet(
                storage: storage,
                isPresented: $showAddItem
            )
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteMemberSheet(
                isPresented: $showInviteSheet,
                onInvite: { email in inviteMember(email: email) }
            )
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            fetchMembers()
            syncItems()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.6)) { animateItems = false }
            }
        }
    }

    // MARK: - Helpers

    private func isOwnerMember(_ member: StorageMemberInfo) -> Bool {
        member.userId == storage.owner?.serverId
    }

    // MARK: - Item Sync

    private func syncItems() {
        Task {
            do {
                try await SyncService.shared.syncStorageItems(for: storage, in: modelContext)
            } catch {
                print("Failed to sync items: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Member API

    private func fetchMembers() {
        guard let storageServerId = storage.serverId else { return }
        isLoadingMembers = true
        Task {
            do {
                let fetched = try await APIService.shared.fetchMembers(storageId: storageServerId)
                await MainActor.run {
                    members = fetched
                    if let ownerId = storage.owner?.serverId,
                       !members.contains(where: { $0.userId == ownerId }),
                       let ownerName = storage.owner?.username {
                        members.insert(
                            StorageMemberInfo(id: -1, userId: ownerId, username: ownerName, accepted: true),
                            at: 0
                        )
                    }
                    isLoadingMembers = false
                }
            } catch {
                await MainActor.run {
                    if let ownerId = storage.owner?.serverId,
                       let ownerName = storage.owner?.username {
                        members = [StorageMemberInfo(id: -1, userId: ownerId, username: ownerName, accepted: true)]
                    }
                    isLoadingMembers = false
                }
                print("Failed to fetch members: \(error.localizedDescription)")
            }
        }
    }

    private func removeMember(_ member: StorageMemberInfo) {
        guard let storageServerId = storage.serverId else { return }
        Task {
            do {
                try await APIService.shared.removeMember(storageId: storageServerId, userId: member.userId)
                await MainActor.run {
                    members.removeAll { $0.id == member.id }
                }
            } catch {
                errorMessage = "Failed to remove member: \(error.localizedDescription)"
            }
        }
    }

    private func inviteMember(email: String) {
        guard let storageServerId = storage.serverId else { return }
        Task {
            do {
                let invited = try await APIService.shared.inviteMember(storageId: storageServerId, email: email)
                await MainActor.run {
                    members.append(invited)
                }
            } catch {
                errorMessage = "Failed to invite member: \(error.localizedDescription)"
            }
        }
    }

    private func cancelInvite(_ invite: StorageMemberInfo) {
        guard let storageServerId = storage.serverId else { return }
        Task {
            do {
                try await APIService.shared.removeMember(storageId: storageServerId, userId: invite.userId)
                await MainActor.run {
                    members.removeAll { $0.id == invite.id }
                }
            } catch {
                errorMessage = "Failed to cancel invitation: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Item Deletion

    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let item = storage.items[index]
            Task {
                do {
                    try await SyncService.shared.deleteStorageItemAndSync(item, from: storage, in: modelContext)
                } catch {
                    errorMessage = "Failed to delete item: \(error.localizedDescription)"
                }
            }
        }
    }

    private func deleteShoppingItems(offsets: IndexSet) {
        for index in offsets {
            let item = storage.shoppingItems[index]
            Task {
                do {
                    try await SyncService.shared.deleteShoppingItemAndSync(item, from: storage, in: modelContext)
                } catch {
                    errorMessage = "Failed to delete shopping item: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    StorageDetailView(storage: Storage(name: "Fridge"))
        .modelContainer(for: [User.self, Storage.self, Product.self, StorageItem.self, ShoppingListItem.self], inMemory: true)
}
