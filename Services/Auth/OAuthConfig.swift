import Foundation

/// One provider's OAuth coordinates. Endpoints verified against official docs
/// 2026-08-28 — see docs/api-notes.md.
struct OAuthConfig: Sendable {
    var clientID: String
    var authorizationEndpoint: URL
    var tokenEndpoint: URL
    var scopes: [String]

    var isConfigured: Bool { !clientID.isEmpty }

    init(clientID: String = "", authorize: String, token: String, scopes: [String] = []) {
        self.clientID = clientID
        self.authorizationEndpoint = URL(string: authorize)!
        self.tokenEndpoint = URL(string: token)!
        self.scopes = scopes
    }
}
