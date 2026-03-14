import SwiftUI

struct ProductsView: View {
    @Environment(ProductsContext.self) private var productsContext
    @Environment(ProfileContext.self) private var profileContext
    @State private var viewModel = ProductsViewModel()
    @State private var showEditForm = false
    @State private var editingProduct: Product?

    var filteredProducts: [Product] {
        viewModel.filteredProducts(from: productsContext.products)
    }

    var categories: [String] {
        viewModel.categories(from: productsContext.products)
    }

    private var currentUserId: Int? {
        profileContext.currentUser?.serverId
    }

    private var ownProducts: [Product] {
        guard let currentUserId else { return [] }
        return filteredProducts.filter { $0.ownerId == currentUserId }
    }

    private var globalProducts: [Product] {
        guard let currentUserId else { return filteredProducts }
        return filteredProducts.filter { $0.ownerId != currentUserId }
    }

    var body: some View {
        NavigationStack {
            Group {
                if productsContext.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if productsContext.products.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cube")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        Text("No Products")
                            .font(.headline)
                        Text("Create your first product to get started")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(action: { viewModel.showCreateForm = true }) {
                            Label("Create Product", systemImage: "plus.circle.fill")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        if !categories.isEmpty {
                            Picker("Category", selection: Binding(
                                get: { viewModel.selectedCategory },
                                set: { viewModel.selectedCategory = $0 }
                            )) {
                                Text("All Categories").tag(Optional<String>(nil))
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(Optional<String>(category))
                                }
                            }.padding(.horizontal, 16)
                            .listRowInsets(EdgeInsets())
                        }

                        if !ownProducts.isEmpty {
                            Section("Own products") {
                                ForEach(ownProducts) { product in
                                    ProductListRow(product: product)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                deleteProduct(product)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }

                                            Button {
                                                editingProduct = product
                                                showEditForm = true
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                }
                            }
                        }

                        if !globalProducts.isEmpty {
                            Section("Global products") {
                                ForEach(globalProducts) { product in
                                    ProductListRow(product: product)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .searchable(text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.searchText = $0 }
            ), prompt: "Search products")
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.showCreateForm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel.showCreateForm },
                set: { viewModel.showCreateForm = $0 }
            )) {
                CreateProductSheet(
                    isPresented: Binding(
                        get: { viewModel.showCreateForm },
                        set: { viewModel.showCreateForm = $0 }
                    ),
                    onSave: createProduct
                )
            }
            .sheet(isPresented: $showEditForm) {
                if let product = editingProduct {
                    EditProductSheet(
                        product: product,
                        isPresented: $showEditForm,
                        onSave: saveProductEdits
                    )
                }
            }
            .alert("Error", isPresented: Binding(
                get: { productsContext.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        productsContext.errorMessage = nil
                    }
                }
            )) {
                Button("OK") { productsContext.errorMessage = nil }
            } message: {
                Text(productsContext.errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                Task {
                    await productsContext.fetch()
                }
            }
        }
        .appGradientBackground()
    }

    private func createProduct(name: String, category: String, expirationDays: Int, barcode: String?) {
        Task {
            await productsContext.add(
                name: name,
                category: category,
                expirationDaysDelta: expirationDays,
                barcode: barcode
            )
        }
    }

    private func saveProductEdits(name: String, category: String, expirationDays: Int, barcode: String?) {
        guard let product = editingProduct else { return }

        Task {
            await productsContext.update(
                product: product,
                name: name,
                category: category,
                expirationDaysDelta: expirationDays,
                barcode: barcode
            )
        }
    }

    private func deleteProduct(_ product: Product) {
        Task {
            await productsContext.delete(product)
        }
    }
}

#Preview {
    ProductsView()
}
