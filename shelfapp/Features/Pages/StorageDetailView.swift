import SwiftUI
import SwiftData

struct StorageDetailView: View {
    @Environment(\.modelContext) var modelContext
    var storage: Storage
    @State private var showAddItem = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if !storage.items.isEmpty {
                Section("Items in Storage") {
                    ForEach(storage.items) { item in
                        ItemRow(item: item)
                    }
                    .onDelete { offsets in
                        deleteItems(offsets: offsets)
                    }
                }
            }
            
            if !storage.shoppingItems.isEmpty {
                Section("Shopping List") {
                    ForEach(storage.shoppingItems) { item in
                        ShoppingItemRow(item: item)
                    }
                    .onDelete { offsets in
                        deleteShoppingItems(offsets: offsets)
                    }
                }
            }
            
            if storage.items.isEmpty && storage.shoppingItems.isEmpty {
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
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

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

struct ItemRow: View {
    var item: StorageItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product?.name ?? "Unknown")
                    .fontWeight(.semibold)
                if let category = item.product?.category, !category.isEmpty {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let expires = item.expiresAt {
                    Text(expires, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ShoppingItemRow: View {
    var item: ShoppingListItem
    
    var body: some View {
        HStack {
            Text(item.product?.name ?? "Unknown")
            Spacer()
            Text("×\(item.amountToBuy)")
                .fontWeight(.semibold)
        }
    }
}

struct AddItemSheet: View {
    var storage: Storage
    @Binding var isPresented: Bool
    @Environment(\.modelContext) var modelContext
    @State private var selectedProduct: Product?
    @State private var expirationDate: Date = Date().addingTimeInterval(7 * 24 * 3600)
    @Query(sort: \Product.name) var products: [Product]

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Product") {
                    if products.isEmpty {
                        Text("No products available. Create one first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Product", selection: $selectedProduct) {
                            Text("-- Select a product --").tag(Optional<Product>(nil))
                            ForEach(products) { product in
                                Text(product.name).tag(Optional<Product>(product))
                            }
                        }
                    }
                }

                if selectedProduct != nil {
                    Section("Expiration Date") {
                        DatePicker(
                            "Expires",
                            selection: $expirationDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if let product = selectedProduct {
                            addItem(product: product)
                            isPresented = false
                        }
                    }
                    .disabled(selectedProduct == nil)
                }
            }
        }
    }

    private func addItem(product: Product) {
        Task {
            do {
                let item = StorageItem(product: product, expiresAt: expirationDate)
                storage.items.append(item)
                try modelContext.save()

                // Attempt API sync in background
                Task {
                    do {
                        _ = try await SyncService.shared.addStorageItemAndSync(
                            to: storage,
                            product: product,
                            expiresAt: expirationDate,
                            in: modelContext
                        )
                    } catch {
                        print("API sync failed (local item created): \(error.localizedDescription)")
                    }
                }
            } catch {
                print("Failed to add item: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    StorageDetailView(storage: Storage(name: "Fridge"))
        .modelContainer(for: [User.self, Storage.self, Product.self, StorageItem.self, ShoppingListItem.self], inMemory: true)
}
