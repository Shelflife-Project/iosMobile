import Foundation

enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
