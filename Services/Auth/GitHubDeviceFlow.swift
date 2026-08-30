import Foundation

/// GitHub device authorization flow (RFC 8628) — the one secret-free path among
/// our four providers.
/// docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#device-flow
///
/// Endpoints and scope come from the provider's `OAuthConfig`; nothing is retyped.
struct GitHubDeviceFlow: Sendable {
    struct DeviceCode: Decodable, Sendable {
        let deviceCode: String
        let userCode: String
        let verificationUri: String
        let expiresIn: Int
        let interval: Int

        enum CodingKeys: String, CodingKey {
            case deviceCode = "device_code"
            case userCode = "user_code"
            case verificationUri = "verification_uri"
            case expiresIn = "expires_in"
            case interval
        }

        var verificationURL: URL? { URL(string: verificationUri) }
    }

    private struct PollError: Decodable { let error: String }

    let config: OAuthConfig

    func requestCode() async throws -> DeviceCode {
        let data = try await HTTP.send(HTTP.form(
            config.authorizationEndpoint,
            params: ["client_id": config.clientID,
                     "scope": config.scopes.joined(separator: " ")]))
        return try JSONDecoder().decode(DeviceCode.self, from: data)
    }

    /// Polls until the user approves, honouring GitHub's `interval` (+5s on
    /// `slow_down`). Pending and denied both arrive as 200s carrying
    /// `{"error": …}`, so this reads the body rather than the status code.
    ///
    /// Cancellable: the caller is expected to hold the task and cancel it when the
    /// prompt goes away, since the deadline can be 15 minutes out.
    func waitForToken(_ code: DeviceCode) async throws -> OAuthToken {
        let decoder = JSONDecoder()
        let poll = HTTP.form(
            config.tokenEndpoint,
            params: ["client_id": config.clientID,
                     "device_code": code.deviceCode,
                     "grant_type": "urn:ietf:params:oauth:grant-type:device_code"])
        var interval = max(code.interval, 5)
        let deadline = Date().addingTimeInterval(Double(code.expiresIn))

        while Date() < deadline {
            try await Task.sleep(for: .seconds(interval))
            try Task.checkCancellation()
            let data = try await HTTP.send(poll)
            if let token = try? decoder.decode(OAuthToken.self, from: data), !token.accessToken.isEmpty {
                return token
            }
            switch (try? decoder.decode(PollError.self, from: data))?.error ?? "unknown" {
            case "authorization_pending": continue
            case "slow_down": interval += 5
            case "expired_token": throw ServiceError.provider("Code expired — try again")
            case "access_denied": throw ServiceError.provider("Denied on GitHub")
            case let other: throw ServiceError.provider("GitHub: \(other)")
            }
        }
        throw ServiceError.provider("Code expired — try again")
    }
}
