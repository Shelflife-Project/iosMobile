import Foundation

protocol ProductAPI {
    func fetchProducts(search: String, size: Int, page: Int) async throws -> PaginatedResult<Product>
    func fetchCategories() async throws -> [String]
    func createProduct(name: String, category: String, expirationDaysDelta: Int, barcode: String?) async throws -> Product
    func updateProduct(id: Int, name: String, category: String, expirationDaysDelta: Int, barcode: String?) async throws -> Product
    func deleteProduct(id: Int) async throws
}
