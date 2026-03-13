import SwiftUI

struct AddItemSheet: View {
    var storage: Storage
    @Binding var isPresented: Bool
    @Environment(ProductsContext.self) private var productsContext
    @Environment(StorageDetailContext.self) private var storageDetailContext
    @State private var selectedProduct: Product?
    @State private var expirationDate: Date = Date().addingTimeInterval(7 * 24 * 3600)

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Product") {
                    if productsContext.products.isEmpty {
                        Text("No products available. Create one first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Product", selection: $selectedProduct) {
                            Text("-- Select a product --").tag(Optional<Product>(nil))
                            ForEach(productsContext.products) { product in
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
            .onAppear {
                Task {
                    await productsContext.fetch()
                }
            }
        }
    }

    private func addItem(product: Product) {
        Task {
            await storageDetailContext.addItem(
                to: storage,
                product: product,
                expiresAt: expirationDate
            )
        }
    }
}
