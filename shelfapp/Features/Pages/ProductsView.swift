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
                // Try API first — returns a product with serverId
                _ = try await SyncService.shared.addProductAndSync(
                    name: name,
                    category: category,
                    expirationDaysDelta: expirationDays,
                    in: modelContext
                )
            } catch {
                // API failed — create locally without serverId
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

struct ProductListRow: View {
    var product: Product
    
    @State private var isDrawing = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name)
                .font(.headline)
                .fontWeight(.semibold)

            HStack() {
                if !product.category.isEmpty {
                    Label {
                        Text(product.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "tag.circle")
                            .foregroundStyle(.yellow)
                            .symbolEffect(.drawOn, isActive: isDrawing)
                    }
                }
                else {
                    Label {
                        Text("Without category")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "tag.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.red)
                            .symbolEffect(.drawOn, isActive: isDrawing)
                            
                    }
                }
                Spacer()
                Label {
                    Text("\(product.expirationDaysDelta)d")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "calendar")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.purple)
                }
            }.onAppear{
                isDrawing = false
                
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateProductSheet: View {
    @Binding var isPresented: Bool
    var onSave: (String, String, Int) -> Void
    @State private var name = ""
    @State private var category = ""
    @State private var description = ""
    @State private var expirationDays = 7

    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Product Name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Product Description", text: $description)
                    TextField("Category", text: $category)
                        .textInputAutocapitalization(.words)
                    
                }

                Section("Expiration") {
                    Stepper(
                        "Days: \(expirationDays)",
                        value: $expirationDays,
                        in: 0...365
                    )
                }
            }
            .navigationTitle("Create Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name, category, expirationDays)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ProductsView()
        .modelContainer(for: [User.self, Storage.self, Product.self, StorageItem.self, ShoppingListItem.self], inMemory: true)
}
