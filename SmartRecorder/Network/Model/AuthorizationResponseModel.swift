//
//  AuthorizationResponseModel.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 03/12/2025.
//

struct RegisterSuccessResponse: Decodable {
    let userId: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let message: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct APIErrorResponse: Decodable {
    let message: String
    let status: Int?
}
