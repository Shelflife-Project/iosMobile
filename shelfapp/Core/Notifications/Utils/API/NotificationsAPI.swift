import Foundation

struct NotificationsAPI {
    private static let baseURL = "http://localhost:8080/api/storages"
    private static let apiBaseURL = "http://localhost:8080/api"
    
    // Pending Invite operations
    static func fetchPendingInvites(token: String) async throws -> [StorageMemberDTO] {
        let url = URL(string: "\(baseURL)/invites")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode([StorageMemberDTO].self, from: data)
    }
    
    static func acceptInvite(token: String, inviteId: Int) async throws {
        let url = URL(string: "\(baseURL)/invites/\(inviteId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
    
    static func fetchRunningLow(token: String) async throws -> [RunningLowResponseItemDTO] {
        let url = URL(string: "\(apiBaseURL)/runninglow")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode([RunningLowResponseItemDTO].self, from: data)
    }

    static func fetchAboutToExpire(token: String) async throws -> [StorageItemDTO] {
        let url = URL(string: "\(apiBaseURL)/abouttoexpire")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode([StorageItemDTO].self, from: data)
    }

    static func declineInvite(token: String, inviteId: Int) async throws {
        let url = URL(string: "\(baseURL)/invites/\(inviteId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
    
    private static func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch http.statusCode {
        case 200...299:
            return
        case 400:
            throw APIError.serverError(statusCode: 400)
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(statusCode: http.statusCode)
        }
    }
}
