import SwiftUI
import Observation

@MainActor
@Observable
final class NotificationsPageViewModel {
    var animateEnvelope = true

    func triggerAnimations() {
        animateEnvelope = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateEnvelope = false }
        }
    }
}

struct NotificationsPage: View {
    @Environment(NotificationsService.self) private var notificationsContext
    @Environment(StorageService.self) private var storageContext
    @Environment(ShoppingListService.self) private var shoppingListContext
    @State private var viewModel = NotificationsPageViewModel()

    private var sortedAboutToExpire: [StorageItem] {
        notificationsContext.aboutToExpireItems.sorted {
            ($0.expiresAt ?? .distantFuture) < ($1.expiresAt ?? .distantFuture)
        }
    }

    private func daysToExpire(_ item: StorageItem) -> Int {
        guard let expiresAt = item.expiresAt else { return Int.max }
        let diff = expiresAt.startOfDay.timeIntervalSince(Date().startOfDay)
        return Int(ceil(diff / 86400))
    }

    private func isLowItemAlreadyAddedToShoppingList(storageId: Int, lowItem: RunningLowNotification.Item) -> Bool {
        shoppingListContext.items.contains { shopping in
            shopping.storage?.serverId == storageId &&
            shopping.product?.serverId == lowItem.id
        }
    }

    private func isExpiringItemInShoppingList(_ item: StorageItem) -> Bool {
        guard let storageId = item.storage?.serverId,
              let productId = item.product?.serverId else { return false }
        return shoppingListContext.items.contains { shopping in
            shopping.storage?.serverId == storageId &&
            shopping.product?.serverId == productId
        }
    }

    private func addExpiringItemToShoppingList(_ item: StorageItem) {
        guard let storage = item.storage, let product = item.product else { return }
        Task {
            await shoppingListContext.addItem(storage: storage, product: product, amountToBuy: 1)
            await shoppingListContext.fetchAggregated()
        }
    }

    private var pageContent: some View {
        Group {
            if notificationsContext.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if notificationsContext.invites.isEmpty
                        && notificationsContext.runningLowItems.isEmpty
                        && notificationsContext.aboutToExpireItems.isEmpty
                        && notificationsContext.errorMessage == nil {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)
                    Text("No Notifications")
                        .font(.headline)
                    Text("You're all caught up!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                notificationsList
            }
        }
        .appGradientBackground()
        .navigationTitle("Notifications")
        .alert("Error", isPresented: Binding(
            get: { notificationsContext.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    notificationsContext.errorMessage = nil
                }
            }
        )) {
            Button("OK") { notificationsContext.errorMessage = nil }
        } message: {
            Text(notificationsContext.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            Task {
                await notificationsContext.fetchAll()
                await shoppingListContext.fetchAggregated()
            }
            viewModel.triggerAnimations()
        }
        .refreshable {
            await notificationsContext.refreshAll()
            await shoppingListContext.fetchAggregated()
        }
    }

    private var notificationsList: some View {
        List {
            if !sortedAboutToExpire.isEmpty {
                Section {
                    ForEach(0..<sortedAboutToExpire.count, id: \.self) { index in
                        let item = sortedAboutToExpire[index]
                        let days = daysToExpire(item)

                        let alreadyInList = isExpiringItemInShoppingList(item)
                        HStack(spacing: Spacing.md) {
                            RemoteImage(
                                url: item.product?.serverId.flatMap { ResourceURLBuilder.productIconURL(productId: $0) },
                                placeholder: "clock.badge.exclamationmark",
                                size: 40
                            )

                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(item.product?.name ?? "Unknown")
                                    .font(AppFont.bodyEmphasized())
                                Text(item.storage?.name ?? "Unknown storage")
                                    .font(AppFont.caption())
                                    .foregroundStyle(Color.appSecondaryLabel)
                                if days < 0 {
                                    Text("Expired \(abs(days)) day(s) ago")
                                        .font(AppFont.caption2())
                                        .foregroundStyle(Color.appDestructive)
                                } else if days == 0 {
                                    Text("Expires today")
                                        .font(AppFont.caption2())
                                        .foregroundStyle(.orange)
                                } else {
                                    Text("\(days) day(s) left")
                                        .font(AppFont.caption2())
                                        .foregroundStyle(Color.appAccentFresh)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, Spacing.sm)
                        .listCardBackground(accent: days < 0 ? Color.appDestructive : .appAccentWarm)
                        .trailingSwipeActions {
                            SwipeActionButton(
                                title: "Delete",
                                systemImage: "trash",
                                tint: .red,
                                role: .destructive
                            ) {
                                Task { await deleteExpiredItem(item) }
                            }
                            if !alreadyInList {
                                SwipeActionButton(title: "Add to List", systemImage: "cart.badge.plus", tint: .green) {
                                    addExpiringItemToShoppingList(item)
                                }
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundStyle(.orange)
                        Text("Expiring & Expired Items")
                    }
                    .textCase(nil)
                }
            }

            if !notificationsContext.runningLowItems.isEmpty {
                Section {
                    ForEach(notificationsContext.runningLowItems) { notification in
                        ForEach(notification.items) { lowItem in
                            let isInShoppingList = isLowItemAlreadyAddedToShoppingList(storageId: notification.storageId, lowItem: lowItem)

                            HStack(spacing: Spacing.md) {
                                RemoteImage(
                                    url: ResourceURLBuilder.productIconURL(productId: lowItem.id),
                                    placeholder: "cart",
                                    size: 40
                                )

                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    Text(lowItem.productName)
                                        .font(AppFont.bodyEmphasized())
                                    Text(notification.storageName)
                                        .font(AppFont.caption())
                                        .foregroundStyle(Color.appSecondaryLabel)
                                    if lowItem.quantity <= 0 {
                                        Text("Out of stock")
                                            .font(AppFont.caption2())
                                            .foregroundStyle(Color.appDestructive)
                                    } else {
                                        Text("Only \(lowItem.quantity) left")
                                            .font(AppFont.caption2())
                                            .foregroundStyle(.appAccentWarm)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, Spacing.sm)
                            .listCardBackground(accent: .appAccentWarm)
                            .trailingSwipeActions {
                                if isInShoppingList {
                                    SwipeActionButton(title: "In List", systemImage: "cart.fill", tint: .gray) {}
                                        .disabled(true)
                                } else {
                                    SwipeActionButton(title: "Add to List", systemImage: "cart.badge.plus", tint: .green) {
                                        Task {
                                            await notificationsContext.addRunningLowItemToShoppingList(
                                                storageId: notification.storageId,
                                                productId: lowItem.id,
                                                shoppingService: shoppingListContext
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.appAccentWarm)
                        Text("Items Running Low")
                    }
                    .textCase(nil)
                }
            }

            if !notificationsContext.invites.isEmpty {
                Section {
                    ForEach(notificationsContext.invites) { invite in
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "envelope.badge.fill")
                                .foregroundStyle(Color.appPrimary)
                                .font(.system(size: 22))
                                .symbolEffect(.drawOn, isActive: viewModel.animateEnvelope)

                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(invite.storageName)
                                    .font(AppFont.bodyEmphasized())
                                Text("Invited by \(invite.invitedBy)")
                                    .font(AppFont.caption())
                                    .foregroundStyle(Color.appSecondaryLabel)
                            }

                            Spacer()
                        }
                        .padding(.vertical, Spacing.sm)
                        .listCardBackground(accent: .appPrimary)
                        .trailingSwipeActions {
                            SwipeActionButton(title: "Accept", systemImage: "checkmark", tint: .green) {
                                acceptInvite(invite)
                            }
                            SwipeActionButton(title: "Decline", systemImage: "xmark", tint: .red, role: .destructive) {
                                declineInvite(invite)
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.badge.fill")
                            .foregroundStyle(Color.appPrimary)
                        Text("Storage Invitations")
                    }
                    .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    var body: some View {
        NavigationStack {
            pageContent
        }
    }

    private func acceptInvite(_ invite: PendingInviteInfo) {
        Task {
            await notificationsContext.acceptInvite(invite, storageService: storageContext)
        }
    }

    private func declineInvite(_ invite: PendingInviteInfo) {
        Task {
            await notificationsContext.declineInvite(invite)
        }
    }

    private func deleteExpiredItem(_ item: StorageItem) async {
        guard let itemId = item.id,
              let storageId = item.storage?.id else {
            notificationsContext.errorMessage = "Invalid expired item data"
            return
        }
        await notificationsContext.deleteExpiredItem(itemId: itemId, storageId: storageId)
    }
}

#Preview {
    NotificationsPage()
}
