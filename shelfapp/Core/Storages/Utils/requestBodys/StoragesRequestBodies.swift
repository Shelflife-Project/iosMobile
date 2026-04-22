import Foundation

enum StoragesRequestBody {
    struct Upsert: Encodable {
        let name: String
    }
}

enum StoragesRequestDTO {
    struct FetchStorages {
        let search: String
        let page: Int
        let size: Int
    }

    struct StorageId {
        let id: Int
    }

    struct UpdateStorage {
        let id: Int
        let body: StoragesRequestBody.Upsert
    }
}
