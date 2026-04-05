import Foundation

protocol ProductAPI {
    func fetchProducts(search: String, size: Int, page: Int) async throws -> PaginatedResult<Product>
    func fetchCategories() async throws -> [String]
    func createProduct(name: String, category: String, expirationDaysDelta: Int, barcode: String?) async throws -> Product
    func updateProduct(id: Int, name: String, category: String, expirationDaysDelta: Int, barcode: String?) async throws -> Product
    func deleteProduct(id: Int) async throws
}

struct DefaultProductAPI: ProductAPI {
    let http: HTTPClient

    func fetchProducts(search: String = "", size: Int = 0, page: Int = 0) async throws -> PaginatedResult<Product> {
        do {
            let payload: PaginatedResponseDTO<ProductDTO> = try await http.request(.products(search: search, page: page, size: size))
            return PaginatedResult(
                items: payload.data.map { $0.toDomain() },
                currentPage: payload.currentPage,
                totalPages: payload.totalPages,
                totalItems: payload.totalItems,
                pageSize: payload.pageSize,
                hasNext: payload.hasNext,
                hasPrevious: payload.hasPrevious
            )
        } catch {
            let items: [ProductDTO] = try await http.request(.products(search: search, page: page, size: size))
            return PaginatedResult(
                items: items.map { $0.toDomain() },
                currentPage: 0,
                totalPages: 1,
                totalItems: items.count,
                pageSize: items.count,
                hasNext: false,
                hasPrevious: false
            )
        }
    }

    func fetchCategories() async throws -> [String] {
        try await http.request(.categories)
    }

    func createProduct(name: String, category: String, expirationDaysDelta: Int, barcode: String?) async throws -> Product {
        let dto: ProductDTO = try await http.request(.createProduct(ProductUpsertBody(name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode)))
        return dto.toDomain()
    }

    func updateProduct(id: Int, name: String, category: String, expirationDaysDelta: Int, barcode: String?) async throws -> Product {
        let dto: ProductDTO = try await http.request(.updateProduct(id: id, body: ProductUpsertBody(name: name, category: category, expirationDaysDelta: expirationDaysDelta, barcode: barcode)))
        return dto.toDomain()
    }

    func deleteProduct(id: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteProduct(id: id))
    }
}
