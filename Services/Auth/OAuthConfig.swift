import Foundation

/// One provider's OAuth coordinates. Endpoints verified against official docs
/// 2026-08-28 — see docs/api-notes.md.
struct OAuthConfig: Sendable {
    var clientID: String
    var authorizationEndpoint: URL
    var tokenEndpoint: URL
    var scopes: [String]
    /// NOT yet registered: App/Info.plist has no CFBundleURLTypes, so this scheme
    /// does not route back to the app. Required before any redirect flow — see README.
    var redirectScheme: String

    var isConfigured: Bool { !clientID.isEmpty }

    /// The scheme the app intends to use for OAuth callbacks. See the note on
    /// `redirectScheme` above — it is not registered in Info.plist yet.
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
