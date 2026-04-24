import Foundation

enum ProductsRequestBody {
    struct Upsert: Encodable {
        let name: String
        let category: String
        let expirationDaysDelta: Int
        let barcode: String?
    }
}

enum ProductsRequestDTO {
    struct FetchProducts {
        let search: String
        let page: Int
        let size: Int
    }

    struct ProductId {
        let id: Int
    }

    struct UpdateProduct {
        let id: Int
        let body: ProductsRequestBody.Upsert
    }
}
