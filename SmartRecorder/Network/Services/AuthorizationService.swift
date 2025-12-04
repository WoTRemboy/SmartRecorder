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
                    username: payload.username,
                    countRecords: 0,
                    countMinutes: 0
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
            
            do {
                let info = try await fetchRecordInfo()
                await persistUser(from: info)
            } catch {
                logger.error("Failed to fetch recordInfo after login: \(String(describing: error))")
                
                let fallback = User(
                    id: UUID(),
                    email: payload.email,
                    firstName: nil,
                    lastName: nil,
                    username: nil,
                    countRecords: 0,
                    countMinutes: 0
                )
                do {
                    try await saveCurrentUser(fallback)
                    logger.info("Persisted minimal user after login (fallback).")
                } catch {
                    logger.error("Failed to persist minimal user after login: \(String(describing: error))")
                }
            }
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
                let tokens = AuthTokens(
                    accessToken: refresh.accessToken,
                    refreshToken: refresh.refreshToken,
                    expiresAt: Date().addingTimeInterval(300))
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
    
    /// Returns a valid access token. If the current token is expired (with skew),
    /// attempts to refresh it using the stored refresh token and returns the updated access token.
    /// - Parameter skew: Clock skew in seconds to treat the token as expired a bit earlier.
    internal func validAccessToken(skew: TimeInterval = 30) async throws -> String {
        guard let tokens = try TokenService.shared.load() else {
            logger.error("No tokens found in Keychain when requesting valid access token.")
            throw ServiceError.invalidResponse
        }
        if !tokens.isExpired(skew: skew) {
            return tokens.accessToken
        }
        // Token expired, try to refresh
        logger.info("Access token expired, attempting refresh...")
        try await refresh(refreshToken: tokens.refreshToken)
        guard let updated = try TokenService.shared.load(), !updated.isExpired(skew: skew) else {
            logger.error("Token refresh did not yield a valid access token.")
            throw ServiceError.invalidResponse
        }
        return updated.accessToken
    }
    
    /// Fetches user profile and statistics using GET /recordInfo.
    /// Uses a valid Bearer access token, refreshing it beforehand if needed.
    internal func fetchRecordInfo() async throws -> RecordInfoResponse {
        let url = baseURL.appendingPathComponent("recordInfo")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let token = try await validAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }

        if (200..<300).contains(http.statusCode) {
            let info = try JSONDecoder().decode(RecordInfoResponse.self, from: data)
            logger.info("Fetched record info for user: \(info.email, privacy: .private)")
            return info
        } else if let api = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            logger.error("/recordInfo failed with API error. status: \(http.statusCode), message: \(api.message)")
            throw ServiceError.apiError(statusCode: http.statusCode, message: api.message)
        } else {
            let body = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            logger.error("/recordInfo failed with HTTP error. status: \(http.statusCode), body: \(body)")
            throw ServiceError.httpError(statusCode: http.statusCode, body: body)
        }
    }

    /// Maps RecordInfoResponse to local User model and persists it.
    private func persistUser(from info: RecordInfoResponse) async {
        let userId = UUID(uuidString: info.keycloakUserId) ?? UUID()
        // Try to split full name, if present
        var firstName: String? = nil
        var lastName: String? = nil
        if let full = info.fullName?.trimmingCharacters(in: .whitespacesAndNewlines), !full.isEmpty {
            let parts = full.split(separator: " ", maxSplits: 1).map(String.init)
            firstName = parts.first
            if parts.count > 1 { lastName = parts[1] }
        }
        let user = User(
            id: userId,
            email: info.email,
            firstName: firstName,
            lastName: lastName,
            username: info.username,
            countRecords: Int32(info.countRecords),
            countMinutes: Int32(info.countMinutes)
        )
        do {
            try await saveCurrentUser(user)
            logger.info("Persisted user from recordInfo: \(info.email, privacy: .private)")
        } catch {
            logger.error("Failed to persist user from recordInfo: \(String(describing: error))")
        }
    }

    /// Call on app launch to refresh profile if authorized.
    @discardableResult
    internal func refreshProfileOnLaunch() async -> Bool {
        do {
            let info = try await fetchRecordInfo()
            await persistUser(from: info)
            return true
        } catch {
            logger.error("refreshProfileOnLaunch failed: \(String(describing: error))")
            return false
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

