//
//  UserAuthDTO.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 04. 18..
//

import Foundation

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
