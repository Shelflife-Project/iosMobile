import SwiftUI

struct ProductsView: View {
    @Environment(ProductsContext.self) private var productsContext
    @State private var viewModel = ProductsViewModel()

    var filteredProducts: [Product] {
        viewModel.filteredProducts(from: productsContext.products)
    }

    var categories: [String] {
        viewModel.categories(from: productsContext.products)
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

                        ForEach(filteredProducts) { product in
                            ProductListRow(product: product)
                        }
                    }
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
    }

    private func createProduct(name: String, category: String, expirationDays: Int) {
        Task {
            await productsContext.add(
                name: name,
                category: category,
                expirationDaysDelta: expirationDays
            )
        }
    }
}

#Preview {
    ProductsView()
}
