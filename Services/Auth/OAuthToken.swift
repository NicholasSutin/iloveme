import Foundation

/// Standard OAuth 2.0 token response. Providers vary in extras; unknown keys are
/// ignored. `refreshToken`/`expiresIn` are decoded but not yet acted on — there is
/// no refresh path until the Worker proxy exists, so an expired token currently
/// surfaces as an HTTP 401 on the next load.
struct OAuthToken: Codable, Sendable {
    var accessToken: String
    var refreshToken: String?
    var expiresIn: Double?
    var tokenType: String?
    var scope: String?
    var obtainedAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
        case obtainedAt
    }

    var isExpired: Bool {
        guard let expiresIn else { return false }
        return Date() > obtainedAt.addingTimeInterval(expiresIn - 60)
    }
}
