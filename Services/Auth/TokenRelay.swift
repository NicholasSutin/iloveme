import Foundation

/// Client for the Cloudflare Worker that holds the provider client secrets.
///
/// Exists because Strava requires a `client_secret` at both token exchange and
/// refresh, and a secret compiled into an iOS binary is extractable. The app sends
/// an opaque authorization code and gets a token back; the secret never travels
/// here. See worker/README.md.
struct TokenRelay: Sendable {
    let baseURL: URL
    let sharedToken: String

    /// nil when `App/Secrets.plist` is missing, which is a normal state on a fresh
    /// clone. Callers surface it as "not configured" rather than a runtime failure.
    static var configured: TokenRelay? {
        guard let token = AppSecrets.relaySharedToken else { return nil }
        return TokenRelay(baseURL: AppSecrets.relayBaseURL, sharedToken: token)
    }

    func exchange(code: String, provider: ServiceKind) async throws -> OAuthToken {
        try await post("\(provider.rawValue)/exchange", body: ["code": code])
    }

    func refresh(_ refreshToken: String, provider: ServiceKind) async throws -> OAuthToken {
        try await post("\(provider.rawValue)/refresh", body: ["refresh_token": refreshToken])
    }

    private func post(_ path: String, body: [String: String]) async throws -> OAuthToken {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("Bearer \(sharedToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            // The relay returns {"error": …} and never echoes an upstream secret.
            let detail = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"]
            throw ServiceError.provider("Relay \(status): \(detail.map { "\($0)" } ?? "failed")")
        }
        // obtainedAt defaults to now inside OAuthToken's decoder.
        return try JSONDecoder().decode(OAuthToken.self, from: data)
    }
}
