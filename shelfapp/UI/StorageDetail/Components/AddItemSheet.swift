import SwiftUI

struct AddItemSheet: View {
    var storage: Storage
    @Binding var isPresented: Bool
    var onAdded: (() -> Void)? = nil
    @Environment(ProductService.self) private var productsContext
    @Environment(StorageDetailService.self) private var storageDetailContext
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
            .scrollContentBackground(.hidden)
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
                        Task {
                            if let product = selectedProduct {
                                await addItem(product: product)
                                onAdded?()
                                isPresented = false
                            }
                        }
                    }
                    .tint(selectedProduct == nil ? .gray : .accentColor)
                    .disabled(selectedProduct == nil)
                }
            }
            .onAppear {
                Task {
                    if productsContext.products.isEmpty && !productsContext.isLoading {
                        await productsContext.fetch()
                    }
                }
            }
        }
        .appGradientBackground()
    }

    private func addItem(product: Product) async {
        await storageDetailContext.addItem(
            to: storage,
            product: product,
            expiresAt: expirationDate
        )
    }
}
