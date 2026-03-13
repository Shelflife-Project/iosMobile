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

    func addNew(name: String, category: String, expirationDaysDelta: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await apiService.createProduct(
                name: name,
                category: category,
                expirationDaysDelta: expirationDaysDelta
            )
            await fetch()
        } catch {
            errorMessage = "Failed to create product: \(error.localizedDescription)"
        }
    }

    func add(name: String, category: String, expirationDaysDelta: Int, context: Any? = nil) async {
        await addNew(name: name, category: category, expirationDaysDelta: expirationDaysDelta)
    }
}
