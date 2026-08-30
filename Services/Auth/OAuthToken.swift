import Foundation

/// Standard OAuth 2.0 token response. Providers vary in extras; unknown keys are
/// ignored.
///
/// `expiresIn` drives `isExpired`, which `ServiceCard.currentToken()` checks before
/// every load: a `.clientCredentials` provider mints a replacement on the spot.
/// `refreshToken` is still decoded but unused — acting on it means the
/// authorization-code flow, which needs a server. Providers that can neither renew
/// nor refresh surface expiry as an HTTP 401 on the next load, deliberately.
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

    init(accessToken: String) {
        self.accessToken = accessToken
    }

    /// Hand-written because `obtainedAt` is ours, not the provider's.
    ///
    /// Swift's synthesized `Decodable` ignores default values and demands every key
    /// in `CodingKeys`, so a synthesized decode of any real provider payload fails
    /// with `keyNotFound("obtainedAt")` — surfacing as "The data couldn't be read
    /// because it is missing." It cannot simply be dropped from `CodingKeys` either:
    /// it must still be *encoded* into the Keychain, or the stored instant resets on
    /// every read and `isExpired` is permanently false.
    ///
    /// So: absent on a provider payload, meaning the grant is happening now; present
    /// when re-reading our own Keychain copy, where the original instant is the
    /// whole point.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken  = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        expiresIn    = try container.decodeIfPresent(Double.self, forKey: .expiresIn)
        tokenType    = try container.decodeIfPresent(String.self, forKey: .tokenType)
        scope        = try container.decodeIfPresent(String.self, forKey: .scope)
        obtainedAt   = try container.decodeIfPresent(Date.self, forKey: .obtainedAt) ?? Date()
    }

    var isExpired: Bool {
        guard let expiresIn else { return false }
        return Date() > obtainedAt.addingTimeInterval(expiresIn - 60)
    }
}
