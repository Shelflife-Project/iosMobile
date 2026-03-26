import Observation
import Foundation

@MainActor
@Observable
class ProductsContext {
    var products: [Product] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    var currentPage = 0
    var pageSize = 0
    var hasNext = false
    var hasPrevious = false

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func fetch(search: String? = nil, page: Int? = nil, size: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if let search { searchText = search }
        if let page { currentPage = max(0, page) }
        if let size { pageSize = max(0, size) }

        do {
            let result = try await apiService.fetchProductsPage(
                search: searchText,
                size: pageSize,
                page: currentPage
            )
            products = result.items
            hasNext = result.hasNext
            hasPrevious = result.hasPrevious
            currentPage = result.currentPage
        } catch {
            errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            products = []
            hasNext = false
            hasPrevious = false
        }
    }

    func nextPage() async {
        guard hasNext else { return }
        await fetch(page: currentPage + 1)
    }

    func previousPage() async {
        guard hasPrevious else { return }
        await fetch(page: max(0, currentPage - 1))
    }

    func addNew(name: String, category: String, expirationDaysDelta: Int, barcode: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await apiService.createProduct(
                name: name,
                category: category,
                expirationDaysDelta: expirationDaysDelta,
                barcode: barcode
            )
            await fetch()
        } catch {
            errorMessage = "Failed to create product: \(error.localizedDescription)"
        }
    }

    func update(product: Product, name: String, category: String, expirationDaysDelta: Int, barcode: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let productId = product.serverId else { throw APIError.invalidURL }
            _ = try await apiService.updateProduct(
                id: productId,
                name: name,
                category: category,
                expirationDaysDelta: expirationDaysDelta,
                barcode: barcode
            )
            await fetch()
        } catch {
            errorMessage = "Failed to update product: \(error.localizedDescription)"
        }
    }

    func delete(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let productId = product.serverId else { throw APIError.invalidURL }
            try await apiService.deleteProduct(id: productId)
            products.removeAll { $0.id == product.id }
            await fetch()
        } catch {
            errorMessage = "Failed to delete product: \(error.localizedDescription)"
        }
    }

    func add(name: String, category: String, expirationDaysDelta: Int, barcode: String? = nil, context: Any? = nil) async {
        await addNew(name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode)
    }
}
