import SwiftUI

struct ShoppingListView: View {
    @Environment(ShoppingListContext.self) private var shoppingListContext
    @Environment(StorageContext.self) private var storageContext
    @Environment(ProductsContext.self) private var productsContext
    @State private var showAddSheet = false
    @State private var selectedStorageId: Int?
    @State private var selectedProductId: Int?
    @State private var amountToBuy = 1
    @State private var viewModel = ShoppingListViewModel()

    private var availableStorages: [Storage] {
        storageContext.storages.filter { $0.serverId != nil }
    }

    private var availableProducts: [Product] {
        productsContext.products.filter { $0.serverId != nil }
    }

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
                List {
                    ForEach(shoppingListContext.items) { item in
                        HStack(spacing: 12) {
                            RemoteImage(
                                url: item.product?.serverId.flatMap { APIService.shared.productIconURL(productId: $0) },
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
                        .padding(.vertical, 6)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                Task {
                                    await shoppingListContext.deleteItem(item)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                            .accessibilityIdentifier("shopping.delete")

                            Button {
                                Task {
                                    await shoppingListContext.completeItem(item)
                                }
                            } label: {
                                Label("Done", systemImage: "checkmark")
                            }
                            .tint(.green)
                            .accessibilityIdentifier("shopping.done")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Shopping List")
        .appGradientBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
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
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                Form {
                    Picker("Storage", selection: Binding(
                        get: { selectedStorageId },
                        set: { selectedStorageId = $0 }
                    )) {
                        ForEach(availableStorages, id: \.id) { storage in
                            Text(storage.name).tag(storage.serverId as Int?)
                        }
                    }

                    Picker("Product", selection: Binding(
                        get: { selectedProductId },
                        set: { selectedProductId = $0 }
                    )) {
                        ForEach(availableProducts, id: \.id) { product in
                            Text(product.name).tag(product.serverId as Int?)
                        }
                    }

                    Stepper("Amount to buy: \(amountToBuy)", value: $amountToBuy, in: 1...99)
                }
                .navigationTitle("Add Item")
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
                .onAppear {
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
        }
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
}

#Preview {
    NavigationStack {
        ShoppingListView()
    }
}
