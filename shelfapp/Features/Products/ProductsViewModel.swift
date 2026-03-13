import Observation
import Foundation

@MainActor
@Observable
final class ProductsViewModel {
    var showCreateForm = false
    var selectedCategory: String?
    var searchText = ""

    func filteredProducts(from products: [Product]) -> [Product] {
        products.filter { product in
            let matchesSearch = searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText)
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
