import SwiftUI
import Observation

@MainActor
@Observable
final class ShoppingListPageViewModel {
    let emptyTitle = "Shopping List"
    let emptySubtitle = "No items to purchase"

    func itemTitle(for item: ShoppingListItem) -> String {
        item.product?.name ?? "Unknown product"
    }

    func itemAmountText(for item: ShoppingListItem) -> String {
        "Amount: \(item.amountToBuy)"
    }

    func itemStorageName(for item: ShoppingListItem) -> String? {
        item.storage?.name
    }
}

struct ShoppingListPage: View {
    @Environment(ShoppingListService.self) private var shoppingListContext
    @Environment(StorageService.self) private var storageContext
    @Environment(ProductService.self) private var productsContext
    @State private var showAddSheet = false
    @State private var selectedStorageId: Int?
    @State private var selectedProductId: Int?
    @State private var amountToBuy = 1
    @State private var viewModel = ShoppingListPageViewModel()

    private var availableStorages: [Storage] {
        storageContext.storages.filter { $0.serverId != nil }
    }

    private var availableProducts: [Product] {
        productsContext.products.filter { $0.serverId != nil }
    }

    var body: some View {
        content
        .navigationTitle("Shopping List")
        .appGradientBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await prepareAddSheet()
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            Task {
                await shoppingListContext.fetchAggregated()
                if storageContext.storages.isEmpty { await storageContext.fetch() }
                if productsContext.products.isEmpty { await productsContext.fetch() }
            }
        }
        .refreshable {
            await shoppingListContext.fetchAggregated()
        }
        .coloredSheet(isPresented: $showAddSheet, content: { addItemSheet })
        .alert("Error", isPresented: Binding(
            get: { shoppingListContext.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    shoppingListContext.errorMessage = nil
                }
            }
        )) {
            Button("OK") { shoppingListContext.errorMessage = nil }
        } message: {
            Text(shoppingListContext.errorMessage ?? "An unknown error occurred")
        }
    }

    // MARK: - Main Content

    private var content: some View {
        Group {
            if shoppingListContext.isLoading {
                loadingView
            } else if shoppingListContext.items.isEmpty {
                emptyStateView
            } else {
                itemsList
            }
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
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
    }

    private var itemsList: some View {
        List {
            ForEach(shoppingListContext.items) { item in
                itemRow(item)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func itemRow(_ item: ShoppingListItem) -> some View {
        HStack(spacing: 12) {
            RemoteImage(
                url: item.product?.serverId.flatMap { ResourceURLBuilder.productIconURL(productId: $0) },
                placeholder: "cart",
                size: 38
            )

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

            Spacer()

            amountControls(item)
        }
        .padding(.vertical, 6)
        .trailingSwipeActions {
            SwipeActionButton(
                title: "Delete",
                systemImage: "trash",
                tint: .red
            ) {
                Task { await shoppingListContext.deleteItem(item) }
            }
            .accessibilityIdentifier("shopping.delete")

            SwipeActionButton(
                title: "Done",
                systemImage: "checkmark",
                tint: .green
            ) {
                Task { await shoppingListContext.completeItem(item) }
            }
            .accessibilityIdentifier("shopping.done")
        }
    }

    private func amountControls(_ item: ShoppingListItem) -> some View {
        HStack(spacing: 8) {
            Button {
                guard item.amountToBuy > 1 else { return }
                Task {
                    await shoppingListContext.updateItemAmount(item, amountToBuy: item.amountToBuy - 1)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("shopping.minus")

            Button {
                Task {
                    await shoppingListContext.updateItemAmount(item, amountToBuy: item.amountToBuy + 1)
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("shopping.plus")
        }
    }

    // MARK: - Sheets

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                Picker("Storage", selection: Binding(
                    get: { selectedStorageId },
                    set: { selectedStorageId = $0 }
                )) {
                    Text("Select Storage").tag(Optional<Int>.none)
                    ForEach(availableStorages, id: \.id) { storage in
                        Text(storage.name).tag(storage.serverId as Int?)
                    }
                }

                Picker("Product", selection: Binding(
                    get: { selectedProductId },
                    set: { selectedProductId = $0 }
                )) {
                    Text("Select Product").tag(Optional<Int>.none)
                    ForEach(availableProducts, id: \.id) { product in
                        Text(product.name).tag(product.serverId as Int?)
                    }
                }

                Stepper("Amount to buy: \(amountToBuy)", value: $amountToBuy, in: 1...99)
            }
            .navigationTitle("Add Item")
            .scrollContentBackground(.hidden)
            .appGradientBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let storageId = selectedStorageId,
                              let productId = selectedProductId,
                              let storage = storageContext.storages.first(where: { $0.serverId == storageId }),
                              let product = productsContext.products.first(where: { $0.serverId == productId }) else {
                            return
                        }

                        Task {
                            await shoppingListContext.addItem(storage: storage, product: product, amountToBuy: amountToBuy)
                            showAddSheet = false
                            amountToBuy = 1
                        }
                    }
                    .disabled(selectedStorageId == nil || selectedProductId == nil)
                }
            }
            .onAppear(perform: syncAddSheetSelection)
        }
    }

    @MainActor
    private func prepareAddSheet() async {
        if storageContext.storages.isEmpty {
            await storageContext.fetch()
        }
        if productsContext.products.isEmpty {
            await productsContext.fetch()
        }
        syncAddSheetSelection()
        showAddSheet = true
    }

    private func syncAddSheetSelection() {
        let storageIds = Set(availableStorages.compactMap { $0.serverId })
        let productIds = Set(availableProducts.compactMap { $0.serverId })

        if let selectedStorageId, !storageIds.contains(selectedStorageId) {
            self.selectedStorageId = nil
        }
        if let selectedProductId, !productIds.contains(selectedProductId) {
            self.selectedProductId = nil
        }

        if self.selectedStorageId == nil {
            selectedStorageId = availableStorages.first?.serverId
        }
        if self.selectedProductId == nil {
            selectedProductId = availableProducts.first?.serverId
        }
    }
}

#Preview {
    NavigationStack {
        ShoppingListPage()
    }
}
