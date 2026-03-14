import Foundation

final class RunningLowSetting: Identifiable, Hashable {
    var id: UUID = UUID()
    var serverId: Int?
    var productId: Int?
    var productName: String?
    var threshold: Int

    init(productId: Int? = nil, productName: String? = nil, threshold: Int = 2, serverId: Int? = nil) {
        self.productId = productId
        self.productName = productName
        self.threshold = threshold
        self.serverId = serverId
    }

    static func == (lhs: RunningLowSetting, rhs: RunningLowSetting) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
