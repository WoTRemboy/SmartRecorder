//
//  AuthorizationService.swift
//  SmartRecorder
//
//  Created by Roman Tverdokhleb on 26/11/2025.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.transono.recorder", category: "AuthorizationService")

final class AuthorizationService {
    
    internal static let shared = AuthorizationService()
    
    private let session: URLSession = .shared
    private let baseURL: URL = URL(string: "http://localhost:8888")!

    // MARK: - High-level methods integrated into AuthorizationService

    /// Registers a user, saves tokens to Keychain, and returns a formatted string summary.
    /// - Parameters:
    ///   - payload: Registration body
    internal func register(_ payload: RegistrationPayload) async throws {
        let url = baseURL.appendingPathComponent("register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }

        if (200..<300).contains(http.statusCode) {
            let success = try JSONDecoder().decode(RegisterSuccessResponse.self, from: data)
            try TokenService.shared.save(AuthTokens(accessToken: success.accessToken,
                                             refreshToken: success.refreshToken,
                                             expiresIn: success.expiresIn))
            logger.info("User registration succeeded for \(payload.email, privacy: .private). Tokens saved.")
            
            // Persist single user
            if let uuid = UUID(uuidString: success.userId) {
                let user = User(
                    id: uuid,
                    email: payload.email,
                    firstName: payload.firstName,
                    lastName: payload.lastName,
                    username: payload.username
                )
                do {
                    try await saveCurrentUser(user)
                    logger.info("Persisted current user in storage.")
                } catch {
                    logger.error("Failed to persist current user: \(String(describing: error))")
                }
            }
        } else {
            if let api = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                logger.error("Registration failed with API error. status: \(http.statusCode), message: \(api.message)")
                throw ServiceError.apiError(statusCode: http.statusCode, message: api.message)
            } else {
                let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
                logger.error("Registration failed with HTTP error. status: \(http.statusCode), body: \(body)")
                throw ServiceError.httpError(statusCode: http.statusCode, body: body)
            }
        }
    }

    /// Logs in a user, saves tokens to Keychain, and returns a formatted string summary.
    /// - Parameters:
    ///   - payload: Login body
    internal func login(_ payload: LoginPayload) async throws {
        let url = baseURL.appendingPathComponent("login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }
        
        if (200..<300).contains(http.statusCode) {
            let success = try JSONDecoder().decode(LoginResponse.self, from: data)
            try TokenService.shared.save(AuthTokens(accessToken: success.accessToken,
                                                    refreshToken: success.refreshToken,
                                                    expiresIn: success.expiresIn))
            logger.info("Login succeeded for \(payload.email, privacy: .private). Tokens saved.")
        } else {
            if let api = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                logger.error("Login failed with API error. status: \(http.statusCode), message: \(api.message)")
                throw ServiceError.apiError(statusCode: http.statusCode, message: api.message)
            } else {
                let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
                logger.error("Login failed with HTTP error. status: \(http.statusCode), body: \(body)")
                throw ServiceError.httpError(statusCode: http.statusCode, body: body)
            }
        }
    }

    /// Refreshes access token using POST /refresh with Authorization: Bearer {refresh_token}.
    internal func refresh(refreshToken: String) async throws {
        let url = baseURL.appendingPathComponent("refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        if (200..<300).contains(http.statusCode) {
            if let refresh = try? JSONDecoder().decode(RefreshResponse.self, from: data) {
                // Save new tokens
                let tokens = AuthTokens(accessToken: refresh.accessToken,
                                    refreshToken: refresh.refreshToken,
                                    expiresAt: Date().addingTimeInterval(3600))
                try TokenService.shared.save(tokens)
                logger.info("Token refresh succeeded.")
            }
        } else {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                logger.error("Token refresh failed with API error. status: \(http.statusCode), message: \(apiError.message)")
                throw ServiceError.apiError(statusCode: http.statusCode, message: apiError.message)
            } else {
                let bodyString = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
                logger.error("Token refresh failed with HTTP error. status: \(http.statusCode), body: \(bodyString)")
                throw ServiceError.httpError(statusCode: http.statusCode, body: bodyString)
            }
        }
    }
}

// MARK: - Service Error Enum

enum ServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, body: String)
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let status, let body):
            return "HTTP \(status)\n\(body)"
        case .apiError(_, let message):
            return message
        }
    }
}
