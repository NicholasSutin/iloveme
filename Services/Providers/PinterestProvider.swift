import Foundation

/// Pinterest. Approved 2026-08-30, and connected by pasting a token generated in
/// the developer portal rather than by OAuth — so no `client_secret`, no redirect
/// leg, and no Worker.
struct PinterestProvider: ServiceProvider {
    let kind = ServiceKind.pinterest

    let config = OAuthConfig(
        clientID: "1606244",   // the portal calls this "App ID"; public, safe to commit
        authorize: "https://www.pinterest.com/oauth/",
        token: "https://api.pinterest.com/v5/oauth/token",
        scopes: ["boards:read", "pins:read"])   // unused while the token is pasted

    /// **The production-limited token, not the sandbox one.** The portal offers
    /// both. Sandbox tokens are only valid against `api-sandbox.pinterest.com`, a
    /// base URL this provider never calls, and Pinterest states the two are not
    /// interchangeable in either direction. The production token's scopes
    /// (`pins:read`, `boards:read`, `user_accounts:read`) cover both calls below.
    ///
    /// **It expires after 24 hours.** Pinterest classes portal-generated tokens as
    /// *test* tokens — the deliberate cost of skipping OAuth. So this affordance
    /// verifies the integration against real boards; it is not a standing
    /// connection. A lasting one needs the authorization-code flow with a refresh
    /// token, which needs the client secret, which needs a server. That trade is
    /// recorded in docs/registration.md rather than made silently here.
    ///
    /// Expiry therefore shows up as a 401 on most loads. `ServiceStatus` names it
    /// rather than printing the raw JSON body.
    let connect = ConnectAffordance.pastedToken(prompt: "Access token")

    var placeholderRows: [Row] { [Board]().rows }

    func rows(token: String) async throws -> [Row] {
        try await boards(token: token).rows
    }

    // MARK: Data

    struct Board: Sendable {
        var name: String
        var pins: [String]
    }

    // MARK: Fetch

    private static let base = "https://api.pinterest.com/v5"

    /// Trial access allows 1,000 requests per day per app, and 15-minute polling is
    /// 96 polls/day — so the fan-out is capped to stay inside that budget. The cap
    /// bounds the request *count*; concurrency only changes when they are issued.
    func boards(token: String, maxBoards: Int = 10, pinsPerBoard: Int = 10) async throws -> [Board] {
        let data = try await HTTP.get(
            URL(string: "\(Self.base)/boards?page_size=\(maxBoards)")!, bearer: token)

        let targets = JSON.array(JSON.object(data)["items"])
            .prefix(maxBoards)
            .enumerated()
            .compactMap { index, board -> (Int, String, String)? in
                guard let id = board["id"] as? String else { return nil }
                return (index, id, board["name"] as? String ?? "Untitled board")
            }

        return try await withThrowingTaskGroup(of: (Int, Board).self) { group in
            for (index, id, name) in targets {
                group.addTask {
                    let pinData = try await HTTP.get(
                        URL(string: "\(Self.base)/boards/\(id)/pins?page_size=\(pinsPerBoard)")!,
                        bearer: token)
                    let pins = JSON.array(JSON.object(pinData)["items"]).map {
                        JSON.firstText($0, "title", "description") ?? "Untitled pin"
                    }
                    return (index, Board(name: name, pins: pins))
                }
            }
            var collected: [(Int, Board)] = []
            for try await result in group { collected.append(result) }
            return collected.sorted { $0.0 < $1.0 }.map(\.1)   // board order as the API returned it
        }
    }
}

extension [PinterestProvider.Board] {
    var rows: [Row] {
        isEmpty ? [Row("No boards", value: "—")]
                : map { Row($0.name, value: "\($0.pins.count)", children: $0.pins.map { Row($0) }) }
    }
}
