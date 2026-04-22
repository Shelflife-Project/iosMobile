import Foundation

protocol TokenStore: AnyObject {
    var token: String? { get }
    func save(_ token: String)
    func delete()
}
