import Foundation

// MARK: - User DTO (for Auth endpoints)

struct UserAuthDTO: Decodable {
    let id: Int
    let username: String
    let email: String?
    let pfpUrl: String?
    let createdAt: String?
    let isAdmin: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case pfpUrl
        case createdAt
        case isAdmin
        case admin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        pfpUrl = try container.decodeIfPresent(String.self, forKey: .pfpUrl)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin)
            ?? container.decodeIfPresent(Bool.self, forKey: .admin)
    }

    func toDomain() -> User {
        User(username: username, email: email, admin: isAdmin ?? false, serverId: id)
    }
}

// MARK: - Auth Session DTO

struct AuthSessionDTO: Decodable {
    let accessToken: String
    let user: UserAuthDTO?
}

private struct TokenOnlyDTO: Decodable {
    let token: String
}

// MARK: - Auth API Service

extension APIHelper {
    // MARK: - Session Management

    func me() async throws -> User {
        guard let url = normalizeURL("api/auth/me") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = buildHeaders()

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(UserAuthDTO.self, from: data)
        return dto.toDomain()
    }

    // MARK: - Auth Endpoints

    func login(email: String, password: String) async throws -> (accessToken: String, user: User) {
        guard let url = normalizeURL("api/auth/login") else { throw APIError.invalidURL }

        let payload: [String: Any] = ["email": email, "password": password]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()

        if let sessionDTO = try? decoder.decode(AuthSessionDTO.self, from: data) {
            let user = sessionDTO.user?.toDomain() ?? User(username: email, email: email)
            return (sessionDTO.accessToken, user)
        }

        if let tokenDTO = try? decoder.decode(TokenOnlyDTO.self, from: data) {
            return (tokenDTO.token, User(username: email, email: email))
        }

        throw APIError.decodingError(NSError(domain: "AuthAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported login response payload"]))
    }

    func signup(username: String, email: String, password: String, passwordRepeat: String) async throws -> (accessToken: String, user: User) {
        guard let url = normalizeURL("api/auth/signup") else { throw APIError.invalidURL }

        let payload: [String: Any] = [
            "username": username,
            "email": email,
            "password": password,
            "passwordRepeat": passwordRepeat
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        _ = try decoder.decode(UserAuthDTO.self, from: data)

        return try await login(email: email, password: password)
    }

    func logout() {
        // Local logout only - clear token and reset state
        // Backend may not have explicit logout endpoint
        setToken(nil)
    }
}
