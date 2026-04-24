import Foundation

enum Loadable<T> {
    case idle
    case loading
    case loaded(T)
    case failed(APIError)

    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var error: APIError? {
        if case .failed(let error) = self { return error }
        return nil
    }

    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    func map<U>(_ transform: (T) -> U) -> Loadable<U> {
        switch self {
        case .idle: return .idle
        case .loading: return .loading
        case .loaded(let value): return .loaded(transform(value))
        case .failed(let error): return .failed(error)
        }
    }
}

extension Loadable: Equatable where T: Equatable {
    static func == (lhs: Loadable<T>, rhs: Loadable<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading): return true
        case (.loaded(let a), .loaded(let b)): return a == b
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}
