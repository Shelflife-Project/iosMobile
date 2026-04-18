import Foundation

struct RunningLowSettingDTO: Decodable {
    let id: Int
    let product: ProductDTO?
    let threshold: Int

    enum CodingKeys: String, CodingKey {
        case id
        case product
        case threshold
        case runningLow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        product = try container.decodeIfPresent(ProductDTO.self, forKey: .product)
        threshold = try container.decodeIfPresent(Int.self, forKey: .threshold)
            ?? container.decode(Int.self, forKey: .runningLow)
    }

    func toDomain() -> RunningLowSetting {
        return RunningLowSetting(productId: product?.id ?? 0, threshold: threshold, serverId: id)
    }
}
