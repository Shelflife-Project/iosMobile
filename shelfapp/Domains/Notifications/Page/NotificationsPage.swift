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
    @Environment(NotificationsStore.self) private var notificationsContext
    @Environment(StorageStore.self) private var storageContext
    @Environment(ShoppingListStore.self) private var shoppingListContext
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

    private func isAlreadyAddedToShoppingList(_ item: RunningLowNotification) -> Bool {
        unresolvedRunningLowItems(for: item).isEmpty
    }

    private func isLowItemAlreadyAddedToShoppingList(storageId: Int, lowItem: RunningLowNotification.Item) -> Bool {
        shoppingListContext.items.contains { shopping in
            shopping.storage?.serverId == storageId &&
            shopping.product?.serverId == lowItem.id
        }
    }

    private func unresolvedRunningLowItems(for notification: RunningLowNotification) -> [RunningLowNotification.Item] {
        notification.items.filter { lowItem in
            !isLowItemAlreadyAddedToShoppingList(storageId: notification.storageId, lowItem: lowItem)
        }
    }

    var body: some View {
        NavigationStack {
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
                    List {
                        if !sortedAboutToExpire.isEmpty {
                            Section("Expiring & Expired Items") {
                                ForEach(sortedAboutToExpire) { item in
                                    let days = daysToExpire(item)

                                    HStack(spacing: 12) {
                                        RemoteImage(
                                            url: item.product?.serverId.flatMap { ResourceURLBuilder.productIconURL(productId: $0) },
                                            placeholder: "clock.badge.exclamationmark",
                                            size: 40
                                        )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.product?.name ?? "Unknown")
                                                .font(.headline)
                                            Text(item.storage?.name ?? "Unknown storage")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if days < 0 {
                                                Text("Expired \(abs(days)) day(s) ago")
                                                    .font(.caption2)
                                                    .foregroundStyle(.red)
                                            } else if days == 0 {
                                                Text("Expires today")
                                                    .font(.caption2)
                                                    .foregroundStyle(.orange)
                                            } else {
                                                Text("\(days) day(s) left")
                                                    .font(.caption2)
                                                    .foregroundStyle(.green)
                                            }
                                        }

                                        Spacer()
                                    }
                                    .trailingSwipeActions {
                                        SwipeActionButton(
                                            title: "Delete",
                                            systemImage: "trash",
                                            tint: .red,
                                            role: .destructive
                                        ) {
                                            Task {
                                                await notificationsContext.deleteExpiredItem(item)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if !notificationsContext.runningLowItems.isEmpty {
                            Section("Items Running Low") {
                                ForEach(notificationsContext.runningLowItems) { notification in
                                    let unresolvedItems = unresolvedRunningLowItems(for: notification)

                                    ForEach(unresolvedItems) { lowItem in
                                        HStack(spacing: 12) {
                                            RemoteImage(
                                                url: ResourceURLBuilder.productIconURL(productId: lowItem.id),
                                                placeholder: "cart",
                                                size: 40
                                            )

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(lowItem.productName)
                                                    .font(.headline)
                                                Text(notification.storageName)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                if lowItem.quantity <= 0 {
                                                    Text("Out of stock")
                                                        .font(.caption2)
                                                        .foregroundStyle(.red)
                                                } else {
                                                    Text("Only \(lowItem.quantity) left")
                                                        .font(.caption2)
                                                        .foregroundStyle(.orange)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .trailingSwipeActions {
                                            SwipeActionButton(
                                                title: "Add to List",
                                                systemImage: "cart.badge.plus",
                                                tint: .green
                                            ) {
                                                Task {
                                                    await notificationsContext.addRunningLowItemToShoppingList(
                                                        storageId: notification.storageId,
                                                        productId: lowItem.id,
                                                        shoppingListContext: shoppingListContext
                                                    )
                                                }
                                            }
                                        }
                                    }

                                    if isAlreadyAddedToShoppingList(notification) {
                                        Label("\(notification.storageName): already added to shopping list", systemImage: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }

                        if !notificationsContext.invites.isEmpty {
                            Section("Storage Invitations") {
                                ForEach(notificationsContext.invites) { invite in
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.badge.fill")
                                            .foregroundStyle(.orange)
                                            .font(.system(size: 20))
                                            .symbolEffect(.drawOn, isActive: viewModel.animateEnvelope)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(invite.storageName)
                                                .font(.headline)
                                            Text("Invited by \(invite.invitedBy)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                    }
                                    .trailingSwipeActions {
                                        SwipeActionButton(
                                            title: "Accept",
                                            systemImage: "checkmark",
                                            tint: .green
                                        ) {
                                            acceptInvite(invite)
                                        }

                                        SwipeActionButton(
                                            title: "Decline",
                                            systemImage: "xmark",
                                            tint: .red,
                                            role: .destructive
                                        ) {
                                            declineInvite(invite)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
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
    }

    private func acceptInvite(_ invite: PendingInviteInfo) {
        Task {
            await notificationsContext.acceptInvite(invite, storageContext: storageContext)
        }
    }

    private func declineInvite(_ invite: PendingInviteInfo) {
        Task {
            await notificationsContext.declineInvite(invite)
        }
    }
}

#Preview {
    NotificationsPage()
}
