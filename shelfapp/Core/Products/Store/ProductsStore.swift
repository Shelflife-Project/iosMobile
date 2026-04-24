import Foundation
import Observation

@MainActor
@Observable
final class ProductsStore {
    var productsState: Loadable<[Product]> = .idle
    var searchText = ""
    var currentPage = 0
    var pageSize = 0
    var hasNext = false
    var hasPrevious = false
    var actionError: String?

    var products: [Product] { productsState.value ?? [] }
    var isLoading: Bool { productsState.isLoading }
    var errorMessage: String? {
        get { actionError ?? productsState.error?.localizedDescription }
        set {
            actionError = newValue
            if newValue == nil, case .failed = productsState { productsState = .idle }
        }
    }

    init() {}

    func fetch() async { await refresh() }

    func refresh() async {
        productsState = .loading
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let response = try await ProductsAPI.fetchAll(token: token, search: searchText, page: currentPage, size: pageSize > 0 ? pageSize : nil)
            productsState = .loaded(response.data.map { $0.toDomain() })
            hasNext = response.hasNext
            hasPrevious = response.hasPrevious
            currentPage = response.currentPage
        } catch {
            productsState = .failed(.serverMessage("Failed to load products"))
        }
    }

    func fetch(search: String? = nil, page: Int? = nil, size: Int? = nil) async {
        if let search { searchText = search }
        if let page { currentPage = max(0, page) }
        if let size { pageSize = max(0, size) }
        await refresh()
    }

    func remove(id: Int) async {
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            try await ProductsAPI.delete(token: token, id: id)
            if var list = productsState.value {
                list.removeAll { $0.id == id }
                productsState = .loaded(list)
            }
        } catch {
            actionError = "Could not delete item"
        }
    }

    func add(name: String, category: String, expirationDaysDelta: Int, barcode: String?) async {
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let created = try await ProductsAPI.create(token: token, name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode)
            var list = productsState.value ?? []
            list.append(created.toDomain())
            productsState = .loaded(list)
        } catch {
            actionError = "Failed to create product"
        }
    }

    func update(id: Int, name: String, category: String, expirationDaysDelta: Int, barcode: String?) async {
        do {
            guard let token = sharedJWTToken else { throw APIError.unauthorized }
            let updated = try await ProductsAPI.update(token: token, id: id, name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode)
            if var list = productsState.value,
               let idx = list.firstIndex(where: { $0.id == id }) {
                list[idx] = updated.toDomain()
                productsState = .loaded(list)
            }
        } catch {
            actionError = "Failed to update product"
        }
    }

    func update(product: Product, name: String, category: String, expirationDaysDelta: Int, barcode: String?) async {
        guard let id = product.id else { actionError = "Invalid product id"; return }
        await update(id: id, name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode)
    }

    func delete(_ product: Product) async {
        guard let id = product.id else { actionError = "Invalid product id"; return }
        await remove(id: id)
    }

    func nextPage() async {
        guard hasNext else { return }
        await fetch(page: currentPage + 1, size: pageSize)
    }

    func previousPage() async {
        guard hasPrevious else { return }
        await fetch(page: max(0, currentPage - 1), size: pageSize)
    }
}

typealias ProductService = ProductsStore
