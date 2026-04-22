import Foundation

struct AuthAPI {
    private static let baseURL = "http://localhost:8080/api/auth"
    
    static func login(email: String, password: String) async throws -> AuthResponseDTO {
        let url = URL(string: "\(baseURL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = LoginRequestDTO(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(AuthResponseDTO.self, from: data)
    }
    
    static func signup(email: String, username: String, password: String, passwordRepeat: String) async throws -> AuthResponseDTO {
        let url = URL(string: "\(baseURL)/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = SignUpRequestDTO(
            email: email,
            username: username,
            password: password,
            passwordRepeat: passwordRepeat
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(AuthResponseDTO.self, from: data)
    }
    
    static func logout(token: String) async throws {
        let url = URL(string: "\(baseURL)/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
    
    static func changePassword(token: String, oldPassword: String, newPassword: String, newPasswordRepeat: String) async throws {
        let url = URL(string: "\(baseURL)/password/change")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = ChangePasswordRequestDTO(
            oldPassword: oldPassword,
            newPassword: newPassword,
            newPasswordRepeat: newPasswordRepeat
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
    
    static func getMe(token: String) async throws -> UserDTO {
        let url = URL(string: "\(baseURL)/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try JSONDecoder().decode(UserDTO.self, from: data)
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
