import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case networkError(String)
    case invalidResponse
    case decodingError(String)
    case forbidden
    case unauthorized
    case notFound
    case conflict(code: String)
    case validation(fields: [String: String])
    case serverMessage(String)
    case serverError(statusCode: Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .forbidden:
            return "Forbidden"
        case .unauthorized:
            return "Unauthorized — please log in"
        case .notFound:
            return "Resource not found"
        case .conflict(let code):
            return "Conflict: \(code)"
        case .validation(let fields):
            return fields.values.joined(separator: "; ")
        case .serverMessage(let message):
            return message
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .unknown:
            return "An unknown error occurred"
        }
    }

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.forbidden, .forbidden),
             (.unauthorized, .unauthorized),
             (.notFound, .notFound),
             (.unknown, .unknown):
            return true
        case (.networkError(let a), .networkError(let b)): return a == b
        case (.decodingError(let a), .decodingError(let b)): return a == b
        case (.conflict(let a), .conflict(let b)): return a == b
        case (.validation(let a), .validation(let b)): return a == b
        case (.serverMessage(let a), .serverMessage(let b)): return a == b
        case (.serverError(let a), .serverError(let b)): return a == b
        default: return false
        }
    }
}
