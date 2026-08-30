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
    /// Host and scheme are BOTH the scheme name — `iloveme://iloveme` — which looks
    /// odd but is load-bearing. Strava matches this URI's *host* against the
    /// registered Authorization Callback Domain (`iloveme`) and ignores the scheme
    /// entirely, so the conventional `iloveme://oauth` is rejected: its host is
    /// `oauth`. Measured 2026-08-29; the table is in docs/registration.md.
    ///
    /// ASWebAuthenticationSession matches on scheme alone, so it intercepts this fine.
    var redirectURI: String { "\(redirectScheme)://\(redirectScheme)" }

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
