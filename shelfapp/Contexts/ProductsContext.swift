import Observation
import Foundation

@MainActor
@Observable
class ProductsContext {
    var products: [Product] = []
    var isLoading = false
    var errorMessage: String?

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func fetch() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            products = try await apiService.fetchProducts()
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            products = []
        }
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
