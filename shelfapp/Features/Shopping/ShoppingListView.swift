import SwiftUI

struct ShoppingListView: View {
    @Environment(ShoppingListContext.self) private var shoppingListContext
    @Environment(StorageContext.self) private var storageContext
    @State private var viewModel = ShoppingListViewModel()

    var body: some View {
        Group {
            if shoppingListContext.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if shoppingListContext.items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 64))
                        .foregroundStyle(.orange.opacity(0.6))

                    Text(viewModel.emptyTitle)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(viewModel.emptySubtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(shoppingListContext.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.itemTitle(for: item))
                            .font(.headline)
                        Text(viewModel.itemAmountText(for: item))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let storageName = viewModel.itemStorageName(for: item) {
                            Text(storageName)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Shopping List")
        .appGradientBackground()
        .onAppear {
            Task {
                await storageContext.fetch()
                shoppingListContext.sync(from: storageContext.storages)
            }
        }
        .refreshable {
            await storageContext.fetch()
            shoppingListContext.sync(from: storageContext.storages)
        }
    }
}

#Preview {
    NavigationStack {
        ShoppingListView()
    }
}
