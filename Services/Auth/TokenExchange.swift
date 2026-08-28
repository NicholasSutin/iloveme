import Foundation

/// Form-encoded POST to a token endpoint, decoded as an `OAuthToken`.
///
/// Unused today: Strava, Notion and Pinterest all require a `client_secret` we
/// refuse to embed, and GitHub's device flow reads the raw body itself (see
/// `GitHubDeviceFlow`). It is the seam the Cloudflare Worker proxy will call.
enum TokenExchange {
    static func post(
        _ endpoint: URL,
        params: [String: String],
        headers: [String: String] = [:]
    ) async throws -> OAuthToken {
        let data = try await HTTP.send(HTTP.form(endpoint, params: params, headers: headers))
        var token = try JSONDecoder().decode(OAuthToken.self, from: data)
        token.obtainedAt = Date()
        return token
    }
}
