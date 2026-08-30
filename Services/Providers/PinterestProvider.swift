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
        // Requested at mint time. The `_secret` pair is included deliberately: a
        // dashboard that silently omits half your boards is more confusing than one
        // that shows them, and this runs on the owner's own phone. Drop those two
        // to exclude secret boards.
        scopes: ["boards:read", "boards:read_secret", "pins:read", "pins:read_secret"])

    /// The app mints its own tokens from the app secret, pasted once and kept in
    /// the Keychain. No portal round-trip, no browser leg, no server.
    ///
    /// Pinterest issues client-credentials tokens "on behalf of the current app
    /// owner", and here the owner is the only user — so the authorization-code
    /// flow's consent step would be ceremony with nobody to consent. Both calls
    /// below accept the grant: `boards/list` and `boards/list_pins` each list
    /// `client_credentials` in their `security` block in Pinterest's official
    /// OpenAPI spec (v5.28.0).
    ///
    /// Explicitly *not* the portal's "Generate Access Tokens" button, whose tokens
    /// Pinterest classes as test tokens and expires after 24 hours. Minted tokens
    /// last 30 days and `ServiceCard` renews them silently on expiry, so this card
    /// needs no maintenance after the first paste.
    ///
    /// Sandbox tokens cannot work here regardless — they are only valid against
    /// `api-sandbox.pinterest.com`, which `base` below is not.
    ///
    /// Requires two-factor auth on the Pinterest account; Pinterest mandates it for
    /// this grant type. See docs/registration.md.
    let connect = ConnectAffordance.clientCredentials(prompt: "App secret or token")

    /// Pinterest prefixes every access token it issues — `pina` (authorization
    /// code), `pinc` (client credentials), `pinr` (refresh) — and app secrets carry
    /// no such prefix. So one field can take either, and the user pastes whichever
    /// credential they actually have.
    ///
    /// That is not only a convenience. Minting requires two-factor auth on the
    /// account; while that is unavailable, a portal-generated token still connects
    /// the card and exercises the whole data path. The secret remains the better
    /// credential — it renews itself — but it is no longer the only way in.
    func isAccessToken(_ pasted: String) -> Bool { pasted.hasPrefix("pin") }

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
