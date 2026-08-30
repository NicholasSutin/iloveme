import Foundation

/// OAuth 2.0 client-credentials grant (RFC 6749 §4.4).
///
/// The app authenticates as *itself* rather than on behalf of a user. For a
/// single-user dashboard that is not a compromise but the accurate description:
/// Pinterest issues these "on behalf of the current app owner", and the owner is
/// the only user there will ever be. Consent from a third party is the one thing
/// the authorization-code flow adds, and there is no third party here — so this
/// drops the browser leg, the redirect, the URL scheme, and the server that would
/// otherwise have to hold the secret.
///
/// The secret itself lives in the Keychain, pasted once. Neither the repo nor the
/// app binary ever contains it.
struct ClientCredentialsFlow: Sendable {
    let config: OAuthConfig

    /// Exchanges the app secret for an access token.
    ///
    /// The secret is a parameter rather than a stored property so that it exists
    /// only for the duration of the call, and the Keychain stays the single place
    /// it is held.
    func token(secret: String) async throws -> OAuthToken {
        guard config.isConfigured else { throw ServiceError.notConfigured }

        // RFC 6749 §2.3.1: client credentials go in an HTTP Basic header, not the
        // body. Pinterest requires this form specifically.
        let basic = Data("\(config.clientID):\(secret)".utf8).base64EncodedString()

        var params = ["grant_type": "client_credentials"]
        // §3.3: space-delimited. Pinterest accepts commas too, but the RFC form
        // keeps this type usable by any provider that implements the grant.
        if !config.scopes.isEmpty { params["scope"] = config.scopes.joined(separator: " ") }

        let data = try await HTTP.send(HTTP.form(
            config.tokenEndpoint,
            params: params,
            headers: ["Authorization": "Basic \(basic)"]))
        return try JSONDecoder().decode(OAuthToken.self, from: data)
    }
}
