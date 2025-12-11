//
//  AuthorizationPayloadModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 28/11/2025.
//

struct RegistrationPayload: Encodable {
    let username: String
    let email: String
    let password: String
    let firstName: String
    let lastName: String

    init(
        username: String,
        email: String,
        password: String,
        firstName: String,
        lastName: String
    ) {
        self.username = username
        self.email = email
        self.password = password
        self.firstName = firstName
        self.lastName = lastName
    }
}

struct LoginPayload: Encodable {
    let email: String
    let password: String

    init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}
