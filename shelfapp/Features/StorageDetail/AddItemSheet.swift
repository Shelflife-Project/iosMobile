import SwiftUI
import SwiftData

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
                _ = try await SyncService.shared.addStorageItemAndSync(
                    to: storage,
                    product: product,
                    expiresAt: expirationDate,
                    in: modelContext
                )
            } catch {
                do {
                    let item = StorageItem(product: product, expiresAt: expirationDate)
                    storage.items.append(item)
                    try modelContext.save()
                    print("API failed, created item locally: \(error.localizedDescription)")
                } catch {
                    print("Failed to add item locally: \(error.localizedDescription)")
                }
            }
        }
    }
}
