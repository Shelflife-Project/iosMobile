import SwiftUI
import Observation
import Foundation

@MainActor
@Observable
final class ProductsPageViewModel {
    var showCreateForm = false
    var showPaginationSettings = false
    var selectedCategory: String?
    var searchText = ""
    var debouncedSearchText = ""
    var pageSize = 0
    let pageSizeOptions = [0, 5, 10, 15, 20]
    var animateSettings = true
    private var searchDebounceTask: Task<Void, Never>?

    func setSearchText(_ text: String) {
        searchText = text
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                guard !Task.isCancelled else { return }
                debouncedSearchText = text
            } catch {
                return
            }
        }
    }

    func triggerSettingsAnimation() {
        animateSettings = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.6)) { self.animateSettings = false }
        }
    }

    func pageSizeLabel(_ value: Int) -> String {
        value == 0 ? "All" : "\(value)"
    }

    func filteredProducts(from products: [Product]) -> [Product] {
        products.filter { product in
            let matchesSearch = debouncedSearchText.isEmpty || product.name.localizedCaseInsensitiveContains(debouncedSearchText)
            let matchesCategory = selectedCategory == nil || product.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    func categories(from products: [Product]) -> [String] {
        Array(Set(products.map { $0.category }))
            .filter { !$0.isEmpty }
            .sorted()
    }
}

struct ProductsPage: View {
    @Environment(ProductService.self) private var productsContext
    @Environment(ProfileService.self) private var profileContext
    @State private var viewModel = ProductsPageViewModel()
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

    private var pageContent: some View {
        productsList
            .scrollContentBackground(.hidden)
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.showCreateForm = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .coloredSheet(isPresented: Binding(
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
            .coloredSheet(item: $editingProduct) { product in
                EditProductSheet(
                    product: product,
                    isPresented: Binding(
                        get: { editingProduct != nil },
                        set: { isPresented in
                            if !isPresented {
                                editingProduct = nil
                            }
                        }
                    ),
                    onSave: { name, category, expirationDays, barcode in
                        saveProductEdits(product: product, name: name, category: category, expirationDays: expirationDays, barcode: barcode)
                    }
                )
            }
            .coloredSheet(isPresented: Binding(
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
                            .tint(!productsContext.hasPrevious || productsContext.isLoading || viewModel.pageSize == 0 ? .gray : .accentColor)
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
                            .tint(!productsContext.hasNext || productsContext.isLoading || viewModel.pageSize == 0 ? .gray : .accentColor)
                            .disabled(!productsContext.hasNext || productsContext.isLoading || viewModel.pageSize == 0)
                        }
                    }
                    .navigationTitle("List Settings")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                viewModel.showPaginationSettings = false
                            }
                            .tint(.accentColor)
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
                viewModel.debouncedSearchText = productsContext.searchText
                viewModel.pageSize = productsContext.pageSize
                viewModel.triggerSettingsAnimation()
                Task {
                    await productsContext.fetch(search: viewModel.searchText, page: 0, size: viewModel.pageSize)
                }
            }
            .onChange(of: viewModel.debouncedSearchText) { _, search in
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

    var body: some View {
        NavigationStack {
            pageContent
        }
        .appGradientBackground()
    }

    // MARK: - List Content

    private var productsList: some View {
        List {
            // Search and settings controls.
            searchSection

            if productsContext.products.isEmpty && productsContext.isLoading {
                loadingSection
            }

            if productsContext.products.isEmpty && !productsContext.isLoading {
                emptyStateSection
            }

            if !categories.isEmpty {
                categoryFilterRow
            }

            if !ownProducts.isEmpty {
                ownProductsSection
            }

            if !globalProducts.isEmpty {
                globalProductsSection
            }
        }
    }

    private var searchSection: some View {
        Section {
            HStack(spacing: 10) {
                TextField("Search products...", text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.setSearchText($0) }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                    .scrollContentBackground(.hidden)
                    .appGradientBackground()

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
    }

    private var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
    }

    private var emptyStateSection: some View {
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

    private var categoryFilterRow: some View {
        Picker("Category", selection: Binding(
            get: { viewModel.selectedCategory },
            set: { viewModel.selectedCategory = $0 }
        )) {
            Text("All Categories").tag(Optional<String>(nil))
            ForEach(categories, id: \.self) { category in
                Text(category).tag(Optional<String>(category))
            }
        }
        .padding(.horizontal, 16)
        .listRowInsets(EdgeInsets())
    }

    private var ownProductsSection: some View {
        Section("Own products") {
            ForEach(ownProducts) { product in
                ProductListRow(product: product)
                    .trailingSwipeActions {
                        SwipeActionButton(
                            title: "Delete",
                            systemImage: "trash",
                            tint: .red,
                            role: .destructive
                        ) {
                            deleteProduct(product)
                        }

                        SwipeActionButton(
                            title: "Edit",
                            systemImage: "pencil",
                            tint: .blue
                        ) {
                            editingProduct = product
                        }
                    }
            }
        }
    }

    private var globalProductsSection: some View {
        Section("Global products") {
            ForEach(globalProducts) { product in
                ProductListRow(product: product)
            }
        }
    }

}

private extension ProductsPage {
    func createProduct(name: String, category: String, expirationDays: Int, barcode: String?) {
        Task {
            await productsContext.add(
                name: name,
                category: category,
                expirationDaysDelta: expirationDays,
                barcode: barcode
            )
        }
    }

    func saveProductEdits(product: Product, name: String, category: String, expirationDays: Int, barcode: String?) {
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

    func deleteProduct(_ product: Product) {
        Task {
            await productsContext.delete(product)
        }
    }
}

#Preview {
    ProductsPage()
}
