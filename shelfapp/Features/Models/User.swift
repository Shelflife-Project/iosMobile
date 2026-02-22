//
//  User.swift
//  shelfapp
//
//  Created by automation
//

import Foundation
import SwiftData

@Model
final class User: Identifiable, Codable {
    @Attribute(.unique) var id: UUID = UUID()
    var username: String
    var email: String?
    var admin: Bool = false

    init(id: UUID = UUID(), username: String, email: String? = nil, admin: Bool = false) {
        self.id = id
        self.username = username
        self.email = email
        self.admin = admin
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case admin
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encode(admin, forKey: .admin)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        admin = try container.decodeIfPresent(Bool.self, forKey: .admin) ?? false
    }
}
