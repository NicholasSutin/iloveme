import Foundation

/// GitHub. The only provider that connects without a secret, via the RFC 8628
/// device flow — so `authorizationEndpoint` is the device-code endpoint rather
/// than a browser redirect target.
struct GitHubProvider: ServiceProvider {
    let kind = ServiceKind.github

    let config = OAuthConfig(
        clientID: "",          // paste from the portal — see docs/registration.md
        authorize: "https://github.com/login/device/code",
        token: "https://github.com/login/oauth/access_token",
        scopes: ["read:user"])

    let connect = ConnectAffordance.deviceFlow

    var placeholderRows: [Row] { CommitActivity(daily: []).rows }

    func rows(token: String) async throws -> [Row] {
        try await contributions(token: token).rows
    }

    // MARK: Data

    struct CommitActivity: Sendable {
        var daily: [Int]       // oldest first

        var last7: Int { daily.suffix(7).reduce(0, +) }
        var last30: Int { daily.suffix(30).reduce(0, +) }

        var rows: [Row] {
            func count(_ value: Int) -> String { daily.isEmpty ? "—" : "\(value)" }
            return [Row("Last 7 days", value: count(last7)),
                    Row("Last 30 days", value: count(last30)),
                    Row("Days recorded", value: "\(daily.count)")]
        }
    }

    // MARK: Fetch

    func contributions(token: String, days: Int = 30) async throws -> CommitActivity {
        let from = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-Double(days) * 86400))
        let query = """
        query($from: DateTime) { viewer { contributionsCollection(from: $from) {
          contributionCalendar {
            weeks { contributionDays { date contributionCount } } } } } }
        """
        let data = try await HTTP.postJSON(
            URL(string: "https://api.github.com/graphql")!,
            bearer: token,
            body: ["query": query, "variables": ["from": from]])

        // GraphQL reports errors in a 200 body, so parse once and read both shapes.
        let root = JSON.object(data)
        let calendar = JSON.object(root, "data", "viewer", "contributionsCollection", "contributionCalendar")
        guard let weeks = calendar["weeks"] as? [[String: Any]] else {
            let messages = JSON.array(root["errors"]).compactMap { $0["message"] as? String }
            throw ServiceError.provider(messages.first ?? "GraphQL shape mismatch")
        }
        let daily = weeks
            .flatMap { JSON.array($0["contributionDays"]) }
            .sorted { ($0["date"] as? String ?? "") < ($1["date"] as? String ?? "") }
            .map { $0["contributionCount"] as? Int ?? 0 }
        return CommitActivity(daily: daily)
    }
}
