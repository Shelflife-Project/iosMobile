import Foundation

// MARK: - Profile Update DTO

struct UserUpdateDTO: Codable {
    let username: String?
    let email: String?
}

// MARK: - Profile API Service

extension APIHelper {
    // MARK: - User Profile Management

    func updateUser(id: Int, username: String? = nil, email: String? = nil) async throws -> User {
        guard let url = normalizeURL("api/users/\(id)") else { throw APIError.invalidURL }

        var payload: [String: Any] = [:]
        if let username = username { payload["username"] = username }
        if let email = email { payload["email"] = email }

        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        let dto = try decoder.decode(UserAuthDTO.self, from: data)
        return dto.toDomain()
    }

    // MARK: - Profile Picture Management

    func uploadUserProfilePicture(userId: Int, imageData: Data) async throws {
        guard let url = normalizeURL("api/users/\(userId)/pfp") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = buildHeaders()
        request.httpBody = imageData
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
    }
}
