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
                } else {
                    List {
                        Section {
                            HStack(spacing: 10) {
                                TextField("Search products...", text: Binding(
                                    get: { viewModel.searchText },
                                    set: { viewModel.searchText = $0 }
                                ))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                                Button {
                                    viewModel.showPaginationSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title3)
                                        .symbolEffect(.pulse, isActive: viewModel.animateSettings)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityLabel("Pagination settings")
                            }
                        }

                        if productsContext.products.isEmpty {
                            Section {
                                VStack(spacing: 12) {
                                    Image(systemName: "cube")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.gray)
                                    Text("No products found")
                                        .font(.headline)
                                    Text("Create your first product to get started")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                            }
                        }

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
            .sheet(isPresented: Binding(
                get: { viewModel.showPaginationSettings },
                set: { viewModel.showPaginationSettings = $0 }
            )) {
                NavigationStack {
                    Form {
                        Picker("Page size", selection: Binding(
                            get: { viewModel.pageSize },
                            set: { viewModel.pageSize = $0 }
                        )) {
                            ForEach(viewModel.pageSizeOptions, id: \.self) { size in
                                Text(viewModel.pageSizeLabel(size)).tag(size)
                            }
                        }

                        HStack {
                            Button {
                                Task { await productsContext.previousPage() }
                            } label: {
                                Label("Previous", systemImage: "chevron.left")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!productsContext.hasPrevious || productsContext.isLoading || viewModel.pageSize == 0)

                            Spacer()
                            Text("Page \(productsContext.currentPage + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()

                            Button {
                                Task { await productsContext.nextPage() }
                            } label: {
                                Label("Next", systemImage: "chevron.right")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!productsContext.hasNext || productsContext.isLoading || viewModel.pageSize == 0)
                        }
                    }
                    .navigationTitle("List Settings")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                viewModel.showPaginationSettings = false
                            }
                        }
                    }
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
                viewModel.searchText = productsContext.searchText
                viewModel.pageSize = productsContext.pageSize
                viewModel.triggerSettingsAnimation()
                Task {
                    await productsContext.fetch(search: viewModel.searchText, page: 0, size: viewModel.pageSize)
                }
            }
            .onChange(of: viewModel.searchText) { _, search in
                Task {
                    await productsContext.fetch(search: search, page: 0)
                }
            }
            .onChange(of: viewModel.pageSize) { _, pageSize in
                Task {
                    await productsContext.fetch(page: 0, size: pageSize)
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
