import Foundation
import Security

/// A pair of authentication tokens with expiration information.
struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    /// Absolute expiration date for the access token.
    let expiresAt: Date

    init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    /// Returns true if the access token is expired (with optional clock skew).
    internal func isExpired(skew seconds: TimeInterval = 30) -> Bool {
        Date().addingTimeInterval(seconds) >= expiresAt
    }
}

/// Errors thrown by TokenService.
enum TokenServiceError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode tokens"
        case .decodingFailed:
            return "Failed to decode tokens"
        case .keychainError(let status):
            if let message = SecCopyErrorMessageString(status, nil) as String? {
                return "Keychain error: \(message) (\(status))"
            } else {
                return "Keychain error: \(status)"
            }
        }
    }
}

/// Stores and retrieves auth tokens securely in the Keychain.
final class TokenService {
    private let service = "SmartRecorder.AuthTokens"
    private let account = "default"
    
    static let shared = TokenService()

    internal init() {}

    /// Save tokens to Keychain. Overwrites existing value if present.
    internal func save(_ tokens: AuthTokens) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(tokens)
        } catch {
            throw TokenServiceError.encodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status: OSStatus
        if try exists() {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            status = SecItemAdd(addQuery as CFDictionary, nil)
        }

        guard status == errSecSuccess else { throw TokenServiceError.keychainError(status) }
    }

    /// Load tokens from Keychain.
    internal func load() throws -> AuthTokens? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw TokenServiceError.keychainError(status)
        }

        do {
            return try JSONDecoder().decode(AuthTokens.self, from: data)
        } catch {
            throw TokenServiceError.decodingFailed
        }
    }

    /// Delete tokens from Keychain.
    internal func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenServiceError.keychainError(status)
        }
    }

    /// Returns true if there are non-expired tokens available.
    internal func hasValidAccessToken(skew seconds: TimeInterval = 30) -> Bool {
        guard let tokens = try? load() else { return false }
        return !tokens.isExpired(skew: seconds)
    }

    /// Adds a Bearer Authorization header if a token exists and is not expired.
    /// - Returns: Updated request, or the same request if no valid token.
    internal func applyAuthorization(to request: URLRequest) -> URLRequest {
        var req = request
        if let tokens = try? load(), !tokens.isExpired() {
            req.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    // MARK: - Helpers
    
    internal func exists() throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanFalse as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecItemNotFound { return false }
        guard status == errSecSuccess else { throw TokenServiceError.keychainError(status) }
        return true
    }
}
