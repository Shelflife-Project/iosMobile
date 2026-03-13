import Foundation
import Security

class AuthService {
    static let shared = AuthService()

    private let apiService = APIService.shared
    private let tokenKey = "shelflife_auth_token"

    // MARK: - Token Management

    func getStoredToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func saveToken(_ token: String) {
        clearToken()

        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary, nil)
        APIService.shared.setToken(token)
    }

    func clearToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]

        SecItemDelete(query as CFDictionary)
        APIService.shared.setToken(nil)
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }

        guard let url = URL(string: "\(APIService.shared.baseURL)/api/auth/login") else {
            throw APIError.invalidURL
        }

        let payload: [String: Any] = [
            "email": email,
            "password": password
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw AuthError.invalidCredentials
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let loginResponse = try decoder.decode(LoginResponseDTO.self, from: data)

        saveToken(loginResponse.token)

        // User profile is fetched by AuthContext via /me.
    }

    // MARK: - Register
    
    func signup(username: String, email: String, password: String, passwordRepeat: String) async throws {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }

        guard password == passwordRepeat else {
            throw AuthError.passwordMismatch
        }

        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }

        guard let url = URL(string: "\(APIService.shared.baseURL)/api/auth/signup") else {
            throw APIError.invalidURL
        }

        let payload: [String: Any] = [
            "username": username,
            "email": email,
            "password": password,
            "passwordRepeat": passwordRepeat
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            if httpResponse.statusCode == 400 {
                let decoder = JSONDecoder()
                if let error = try? decoder.decode(SignupErrorDTO.self, from: data) {
                    throw AuthError.signupError(error)
                }
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        _ = try JSONDecoder().decode(UserDTO.self, from: data)
    }

    // MARK: - User

    func fetchCurrentUser() async throws -> User {
        guard let token = getStoredToken() else {
            throw AuthError.noToken
        }

        guard let url = URL(string: "\(APIService.shared.baseURL)/api/auth/me") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            clearToken()
            throw AuthError.tokenExpired
        }

        let decoder = JSONDecoder()
        let userDTO = try decoder.decode(UserDTO.self, from: data)
        return userDTO.toDomain()
    }

    func logout() {
        clearToken()
    }

    // MARK: - Computed Properties

    var baseURL: String {
        AppConfig.baseURL
    }
}

enum AuthError: LocalizedError {
    case invalidInput
    case invalidEmail
    case passwordMismatch
    case invalidCredentials
    case noToken
    case tokenExpired
    case signupError(SignupErrorDTO)

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please fill in all fields"
        case .invalidEmail:
            return "Invalid email address"
        case .passwordMismatch:
            return "Passwords do not match"
        case .invalidCredentials:
            return "Invalid email or password"
        case .noToken:
            return "Not authenticated"
        case .tokenExpired:
            return "Your session has expired, please log in again"
        case .signupError(let error):
            if let email = error.email {
                return email
            } else if let username = error.username {
                return username
            } else if let password = error.password {
                return password
            }
            return error.error ?? "Signup failed"
        }
    }
}

// MARK: - DTOs

struct LoginResponseDTO: Codable {
    let token: String
}

struct SignupErrorDTO: Codable {
    let username: String?
    let email: String?
    let password: String?
    let passwordRepeat: String?
    let error: String?
}
