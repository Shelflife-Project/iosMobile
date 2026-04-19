import Foundation

struct DefaultStorageAPI: StorageAPI {
    let http: StoragesHTTPClient

    init(http: StoragesHTTPClient) {
        self.http = http
    }

    init() {
        self.init(http: DefaultStoragesHTTPClient())
    }

    func fetchStorages(search: String = "", size: Int = 0, page: Int = 0) async throws -> PaginatedResult<Storage> {
        do {
            let payload: PaginatedResponseDTO<StorageDTO> = try await http.request(.storages(.init(search: search, page: page, size: size)))
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
            let items: [StorageDTO] = try await http.request(.storages(.init(search: search, page: page, size: size)))
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
        let dto: StorageDTO = try await http.request(.storage(.init(id: id)))
        return dto.toDomain()
    }

    func createStorage(name: String) async throws -> Storage {
        let dto: StorageDTO = try await http.request(.createStorage(StoragesRequestBody.Upsert(name: name)))
        return dto.toDomain()
    }

    func updateStorageName(id: Int, name: String) async throws -> Storage {
        let dto: StorageDTO = try await http.request(.updateStorage(.init(id: id, body: StoragesRequestBody.Upsert(name: name))))
        return dto.toDomain()
    }

    func deleteStorage(id: Int) async throws {
        let _: EmptyResponse = try await http.request(.deleteStorage(.init(id: id)))
    }
}
