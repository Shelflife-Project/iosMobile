import SwiftUI
import SwiftData

struct ProductsView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Product.name) var products: [Product]
    @State private var showCreateForm = false
    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var errorMessage: String?

    var filteredProducts: [Product] {
        products.filter { product in
            let matchesSearch = searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || product.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var categories: [String] {
        Array(Set(products.map { $0.category }))
            .filter { !$0.isEmpty }
            .sorted()
    }

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cube")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        Text("No Products")
                            .font(.headline)
                        Text("Create your first product to get started")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(action: { showCreateForm = true }) {
                            Label("Create Product", systemImage: "plus.circle.fill")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        if !categories.isEmpty {
                            Picker("Category", selection: $selectedCategory) {
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
            .searchable(text: $searchText, prompt: "Search products")
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCreateForm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateForm) {
                CreateProductSheet(
                    isPresented: $showCreateForm,
                    onSave: createProduct
                )
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }

    private func createProduct(name: String, category: String, expirationDays: Int) {
        Task {
            do {
                _ = try await SyncService.shared.addProductAndSync(
                    name: name,
                    category: category,
                    expirationDaysDelta: expirationDays,
                    in: modelContext
                )
            } catch {
                do {
                    let product = Product(
                        name: name,
                        category: category,
                        expirationDaysDelta: expirationDays
                    )
                    modelContext.insert(product)
                    try modelContext.save()
                    print("API failed, created product locally: \(error.localizedDescription)")
                } catch {
                    errorMessage = "Failed to create product: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    ProductsView()
        .modelContainer(for: [User.self, Storage.self, Product.self, StorageItem.self, ShoppingListItem.self], inMemory: true)
}
