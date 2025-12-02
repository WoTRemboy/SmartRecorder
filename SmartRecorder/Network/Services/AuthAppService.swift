import Foundation
import CoreData

extension AuthorizationService {
    
    private var _userService: UserEntityService { UserEntityService() }

    /// Returns the only stored user (if any).
    internal func currentUser() async throws -> User? {
        try await _userService.current()
    }

    /// Saves (replaces) the single stored user.
    internal func saveCurrentUser(_ user: User) async throws {
        try await _userService.replaceCurrent(with: user)
    }

    /// Clears all stored users.
    internal func clearUserStorage() async throws {
        try await _userService.delete()
    }

    /// Returns true if there is a valid (non-expired) access token in Keychain.
    internal func isAuthorized() -> Bool {
        TokenService.shared.hasValidAccessToken()
    }

    /// Returns a bearer token string if available, for debugging or manual use.
    internal func currentBearerHeader() -> String? {
        guard let tokens = try? TokenService.shared.load(), !tokens.isExpired() else { return nil }
        return "Bearer \(tokens.accessToken)"
    }
}
