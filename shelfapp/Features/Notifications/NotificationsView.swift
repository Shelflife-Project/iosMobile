import SwiftUI

struct NotificationsView: View {
    @Environment(NotificationsContext.self) private var notificationsContext
    @Environment(StorageContext.self) private var storageContext
    @Environment(ShoppingListContext.self) private var shoppingListContext
    @State private var viewModel = NotificationsViewModel()

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
        shoppingListContext.items.contains { shopping in
            shopping.storage?.serverId == item.storage.serverId &&
            shopping.product?.serverId == item.product.serverId
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
                    ScrollView {
                        LazyVStack(spacing: 14) {
                        if !sortedAboutToExpire.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                sectionHeader(icon: "clock.badge.exclamationmark.fill", color: .orange, title: "Expiring & Expired Items")

                                ForEach(sortedAboutToExpire) { item in
                                    let days = daysToExpire(item)
                                    let isExpired = days < 0

                                    HStack(spacing: 12) {
                                        RemoteImage(
                                            url: item.product?.serverId.flatMap { APIService.shared.productIconURL(productId: $0) },
                                            placeholder: "clock.badge.exclamationmark",
                                            size: 40
                                        )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.product?.name ?? "Unknown")
                                                .font(.headline)
                                            Text(item.storage?.name ?? "Unknown storage")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if isExpired {
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

                                        if isExpired {
                                            Button {
                                                Task {
                                                    await notificationsContext.deleteExpiredItem(item)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.red)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color(.secondarySystemBackground).opacity(0.75))
                                    )
                                }
                            }
                        }

                        if !notificationsContext.runningLowItems.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                sectionHeader(icon: "exclamationmark.triangle.fill", color: .yellow, title: "Items Running Low")

                                ForEach(notificationsContext.runningLowItems) { item in
                                    HStack(spacing: 12) {
                                        RemoteImage(
                                            url: item.product.serverId.flatMap { APIService.shared.productIconURL(productId: $0) },
                                            placeholder: "cart",
                                            size: 40
                                        )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.product.name)
                                                .font(.headline)
                                            Text(item.storage.name)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if item.amount <= 0 {
                                                Text("Out of stock")
                                                    .font(.caption2)
                                                    .foregroundStyle(.red)
                                            } else {
                                                Text("Only \(item.amount) left")
                                                    .font(.caption2)
                                                    .foregroundStyle(.orange)
                                            }
                                        }

                                        Spacer()

                                        if isAlreadyAddedToShoppingList(item) {
                                            Label("Added", systemImage: "checkmark")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                        } else {
                                            Button {
                                                Task {
                                                    await notificationsContext.addRunningLowToShoppingList(item, shoppingListContext: shoppingListContext)
                                                }
                                            } label: {
                                                Label("Add", systemImage: "cart.badge.plus")
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(.green)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color(.secondarySystemBackground).opacity(0.75))
                                    )
                                }
                            }
                        }

                        if !notificationsContext.invites.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                sectionHeader(icon: "envelope.open.fill", color: .orange, title: "Storage Invitations")

                                ForEach(notificationsContext.invites) { invite in
                                    InviteNotificationRow(
                                        invite: invite,
                                        animateEnvelope: viewModel.animateEnvelope,
                                        onAccept: { acceptInvite(invite) },
                                        onDecline: { declineInvite(invite) }
                                    )
                                }
                            }
                        }
                    }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
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

    private func sectionHeader(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
        }
        .padding(.horizontal, 2)
    }
}

#Preview {
    NotificationsView()
}
