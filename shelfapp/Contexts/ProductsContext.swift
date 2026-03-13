import Observation
import SwiftData

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

    func loadLocal(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Product>(sortBy: [SortDescriptor(\Product.name)])
            products = try context.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    func fetch(context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let remoteProducts = try await apiService.fetchProducts()
            try syncPersistedProducts(remoteProducts, context: context)
            loadLocal(context: context)
        } catch {
            errorMessage = "Failed to fetch products: \(error.localizedDescription)"
            loadLocal(context: context)
        }
    }

    func add(name: String, category: String, expirationDaysDelta: Int, context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let newProduct = try await apiService.createProduct(
                name: name,
                category: category,
                expirationDaysDelta: expirationDaysDelta
            )

            if let serverId = newProduct.serverId,
               let existing = try findProduct(byServerId: serverId, context: context) {
                existing.name = newProduct.name
                existing.category = newProduct.category
                existing.expirationDaysDelta = newProduct.expirationDaysDelta
                existing.barcode = newProduct.barcode
            } else {
                context.insert(newProduct)
            }

            try context.save()
            loadLocal(context: context)
        } catch {
            do {
                let localProduct = Product(
                    name: name,
                    category: category,
                    expirationDaysDelta: expirationDaysDelta
                )
                context.insert(localProduct)
                try context.save()
                loadLocal(context: context)
            } catch {
                errorMessage = "Failed to create product: \(error.localizedDescription)"
            }
        }
    }

    private func syncPersistedProducts(_ remoteProducts: [Product], context: ModelContext) throws {
        let localProducts = try context.fetch(FetchDescriptor<Product>())
        var localByServerId: [Int: Product] = [:]

        for product in localProducts {
            if let serverId = product.serverId {
                localByServerId[serverId] = product
            }
        }

        let remoteServerIds = Set(remoteProducts.compactMap { $0.serverId })

        for remote in remoteProducts {
            guard let remoteId = remote.serverId else { continue }

            if let existing = localByServerId[remoteId] {
                existing.name = remote.name
                existing.category = remote.category
                existing.expirationDaysDelta = remote.expirationDaysDelta
                existing.barcode = remote.barcode
            } else {
                context.insert(remote)
            }
        }

        for local in localProducts {
            guard let localId = local.serverId else { continue }
            if !remoteServerIds.contains(localId) {
                context.delete(local)
            }
        }

        try context.save()
    }

    private func findProduct(byServerId serverId: Int, context: ModelContext) throws -> Product? {
        let descriptor = FetchDescriptor<Product>()
        return try context.fetch(descriptor).first { $0.serverId == serverId }
    }
}
