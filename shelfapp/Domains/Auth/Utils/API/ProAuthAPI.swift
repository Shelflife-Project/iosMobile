//
//  ProAuthAPI.swift
//  shelfapp
//
//  Created by Andras Preisler on 2026. 04. 18..
//

import Foundation

protocol AuthAPI {
    func login(email: String, password: String) async throws -> (token: String, user: User)
    func signup(username: String, email: String, password: String, passwordRepeat: String) async throws -> (token: String, user: User)
    func me() async throws -> User
    func changePassword(oldPassword: String, newPassword: String, newPasswordRepeat: String) async throws
    func logout(token: String?) async throws
}
