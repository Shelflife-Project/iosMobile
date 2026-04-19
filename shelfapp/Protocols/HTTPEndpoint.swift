import Foundation

protocol HTTPEndpoint {
    var path: String { get }
    var method: String { get }
    var queryItems: [URLQueryItem] { get }
    var body: AnyEncodable? { get }
    var rawBody: Data? { get }
    var contentType: String? { get }
}

extension HTTPEndpoint {
    var queryItems: [URLQueryItem] { [] }
    var body: AnyEncodable? { nil }
    var rawBody: Data? { nil }
    var contentType: String? { nil }
}
