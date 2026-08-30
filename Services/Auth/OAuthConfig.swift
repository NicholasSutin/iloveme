import Foundation

/// One provider's OAuth coordinates. Endpoints verified against official docs
/// 2026-08-28 — see docs/api-notes.md.
struct OAuthConfig: Sendable {
    var clientID: String
    var authorizationEndpoint: URL
    var tokenEndpoint: URL
    var scopes: [String]
    var redirectScheme: String

    var isConfigured: Bool { !clientID.isEmpty }

    /// The redirect target sent to the provider.
    ///
    /// The `oauth` host is not decorative. Strava matches this URI's *host* against
    /// the registered Authorization Callback Domain and ignores the scheme entirely,
    /// so the domain must be registered as `oauth` for this to be accepted — with a
    /// domain of `iloveme` this exact URI is rejected. Verified both directions
    /// against the live authorize endpoint 2026-08-29; table in docs/registration.md.
    ///
    /// One URI serves every provider: ASWebAuthenticationSession delivers the callback
    /// to the session that started it, so a shared host creates no ambiguity.
    var redirectURI: String { "\(redirectScheme)://oauth" }

    /// Registered in App/Info.plist under CFBundleURLTypes.
    static let redirectScheme = "iloveme"

    init(clientID: String = "",
         authorize: String,
         token: String,
         scopes: [String] = [],
         redirectScheme: String = OAuthConfig.redirectScheme) {
        self.clientID = clientID
        self.authorizationEndpoint = URL(string: authorize)!
        self.tokenEndpoint = URL(string: token)!
        self.scopes = scopes
        self.redirectScheme = redirectScheme
    }
}
