import Observation
import Foundation
import SwiftUI

@MainActor
@Observable
final class ProductsViewModel {
    var showCreateForm = false
    var showPaginationSettings = false
    var selectedCategory: String?
    var searchText = ""
    var pageSize = 0
    let pageSizeOptions = [0, 5, 10, 15, 20]
    var animateSettings = true

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
