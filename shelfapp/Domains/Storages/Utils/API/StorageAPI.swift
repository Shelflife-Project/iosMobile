import Foundation

protocol StorageAPI {
    func fetchStorages(search: String, size: Int, page: Int) async throws -> PaginatedResult<Storage>
    func fetchStorage(id: Int) async throws -> Storage
    func createStorage(name: String) async throws -> Storage
    func updateStorageName(id: Int, name: String) async throws -> Storage
    func deleteStorage(id: Int) async throws
}
