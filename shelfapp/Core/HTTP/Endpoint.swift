import Foundation

struct Endpoint {
    let method: String
    let path: String
    var queryItems: [URLQueryItem] = []
    var body: (any Encodable)? = nil
    var rawBody: Data? = nil
    var contentType: String? = "application/json"
    var requiresAuth: Bool = true

    // MARK: - Factories

    static func get(_ path: String, queryItems: [URLQueryItem] = [], requiresAuth: Bool = true) -> Endpoint {
        Endpoint(method: "GET", path: path, queryItems: queryItems, requiresAuth: requiresAuth)
    }

    static func post(_ path: String, body: (any Encodable)? = nil, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(method: "POST", path: path, body: body, requiresAuth: requiresAuth)
    }

    static func patch(_ path: String, body: (any Encodable)? = nil, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(method: "PATCH", path: path, body: body, requiresAuth: requiresAuth)
    }

    static func put(_ path: String, body: (any Encodable)? = nil, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(method: "PUT", path: path, body: body, requiresAuth: requiresAuth)
    }

    static func delete(_ path: String, requiresAuth: Bool = true) -> Endpoint {
        Endpoint(method: "DELETE", path: path, requiresAuth: requiresAuth)
    }

    static func multipart(_ path: String, data: Data, mimeType: String, fieldName: String = "file", requiresAuth: Bool = true) -> Endpoint {
        let boundary = UUID().uuidString
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"upload\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return Endpoint(
            method: "POST",
            path: path,
            rawBody: body,
            contentType: "multipart/form-data; boundary=\(boundary)",
            requiresAuth: requiresAuth
        )
    }
}
