import Foundation

/// One provider's OAuth coordinates. Endpoints verified against official docs
/// 2026-08-28 — see docs/api-notes.md.
struct OAuthConfig: Sendable {
    var clientID: String
    var authorizationEndpoint: URL
    var tokenEndpoint: URL
    var scopes: [String]
    var redirectScheme: String   // must match CFBundleURLTypes in App/Info.plist

    var isConfigured: Bool { !clientID.isEmpty }

    /// The app's single registered callback scheme.
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
