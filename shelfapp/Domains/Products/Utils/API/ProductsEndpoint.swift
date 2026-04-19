import Foundation

enum ProductsEndpoint: HTTPEndpoint {
    case products(ProductsRequestDTO.FetchProducts)
    case categories
    case createProduct(ProductsRequestBody.Upsert)
    case updateProduct(ProductsRequestDTO.UpdateProduct)
    case deleteProduct(ProductsRequestDTO.ProductId)

    var path: String {
        switch self {
        case .products: return "/api/products"
        case .categories: return "/api/products/categories"
        case .createProduct: return "/api/products"
        case .updateProduct(let request): return "/api/products/\(request.id)"
        case .deleteProduct(let request): return "/api/products/\(request.id)"
        }
    }

    var method: String {
        switch self {
        case .createProduct:
            return "POST"
        case .updateProduct:
            return "PATCH"
        case .deleteProduct:
            return "DELETE"
        case .products, .categories:
            return "GET"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .products(request):
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
        case .createProduct(let body): return AnyEncodable(body)
        case .updateProduct(let request): return AnyEncodable(request.body)
        default: return nil
        }
    }

    var contentType: String? {
        switch self {
        case .createProduct, .updateProduct:
            return "application/json"
        default:
            return nil
        }
    }
}
