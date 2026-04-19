import Foundation

enum StoragesEndpoint: HTTPEndpoint {
    case storages(StoragesRequestDTO.FetchStorages)
    case storage(StoragesRequestDTO.StorageId)
    case createStorage(StoragesRequestBody.Upsert)
    case updateStorage(StoragesRequestDTO.UpdateStorage)
    case deleteStorage(StoragesRequestDTO.StorageId)

    var path: String {
        switch self {
        case .storages: return "/api/storages"
        case .storage(let request): return "/api/storages/\(request.id)"
        case .createStorage: return "/api/storages"
        case .updateStorage(let request): return "/api/storages/\(request.id)"
        case .deleteStorage(let request): return "/api/storages/\(request.id)"
        }
    }

    var method: String {
        switch self {
        case .createStorage:
            return "POST"
        case .updateStorage:
            return "PATCH"
        case .deleteStorage:
            return "DELETE"
        case .storages, .storage:
            return "GET"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .storages(request):
            var items = [URLQueryItem(name: "search", value: request.search)]
            if request.size > 0 {
                items.append(URLQueryItem(name: "page", value: String(request.page)))
                items.append(URLQueryItem(name: "size", value: String(request.size)))
            }
            return items
        default:
            return []
        }
    }

    var body: AnyEncodable? {
        switch self {
        case .createStorage(let body): return AnyEncodable(body)
        case .updateStorage(let request): return AnyEncodable(request.body)
        default: return nil
        }
    }

    var contentType: String? {
        switch self {
        case .createStorage, .updateStorage:
            return "application/json"
        default:
            return nil
        }
    }
}
