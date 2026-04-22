import Foundation
import Security

final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String

    init(service: String = Bundle.main.bundleIdentifier ?? "shelfapp", account: String = "jwt_token") {
        self.service = service
        self.account = account
    }

    var token: String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    func save(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        delete()
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func delete() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - In-memory store for tests/previews

final class InMemoryTokenStore: TokenStore {
    private(set) var token: String?

    func save(_ token: String) { self.token = token }
    func delete() { token = nil }
}
