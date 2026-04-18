import Foundation

struct DefaultStorageAPI: StorageAPI {
    let http: HTTPClient

    func fetchStorages(search: String = "", size: Int = 0, page: Int = 0) async throws -> PaginatedResult<Storage> {
        do {
            let payload: PaginatedResponseDTO<StorageDTO> = try await http.request(.storages(search: search, page: page, size: size))
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
            let items: [StorageDTO] = try await http.request(.storages(search: search, page: page, size: size))
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

    func fetchStorage(id: Int) async throws -> Storage {
        let dto: StorageDTO = try await http.request(.storage(id: id))
        return dto.toDomain()
    }

    func createStorage(name: String) async throws -> Storage {
        let dto: StorageDTO = try await http.request(.createStorage(StorageUpsertBody(name: name)))
        return dto.toDomain()
    }

    func updateStorageName(id: Int, name: String) async throws -> Storage {
        let dto: StorageDTO = try await http.request(.updateStorage(id: id, body: StorageUpsertBody(name: name)))
        return dto.toDomain()
    }

    func deleteStorage(id: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteStorage(id: id))
    }
}
