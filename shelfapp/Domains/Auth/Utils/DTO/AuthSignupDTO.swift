//
//  AuthSignupDTO.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 04. 18..
//

import Foundation

public struct AuthSignupDTO: Decodable {
    let token: String?
    let accessToken: String?
    let user: UserDTO?
}
