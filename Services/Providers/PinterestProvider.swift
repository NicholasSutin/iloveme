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
        /// The board's true size, from `pin_count` — not the number of pins fetched
        /// below, which is one capped page of them.
        var pinCount: Int
        var pins: [Pin]
        /// Both arrive with the board itself, so a visual board list costs the single
        /// `/boards` request and none of the per-board fan-out.
        var coverURL: URL?
        var thumbnailURLs: [URL]
    }

    struct Pin: Sendable {
        var title: String
        /// nil for video pins, which carry no `images` at all.
        var image: PinImage?
    }

    /// Pinterest publishes each image pin at four fixed sizes. Kept whole rather
    /// than reduced to one URL here, because a list thumbnail and a full-screen
    /// view want different ones and all four arrive in the same payload.
    ///
    /// The URLs are public CDN (`i.pinimg.com`) and need no `Authorization` header,
    /// so a view can hand one straight to `AsyncImage` — verified 2026-08-30, see
    /// docs/api-notes.md §3.4b.
    struct PinImage: Sendable {
        /// Keyed by Pinterest's own size names: `150x150`, `400x300`, `600x`, `1200x`.
        var sizes: [String: URL]

        /// First size present, walking `order`. Pinterest does not guarantee all four
        /// on every pin, so a single hard-coded key would render blanks.
        func url(preferring order: [String]) -> URL? {
            order.lazy.compactMap { sizes[$0] }.first
        }

        var thumbnail: URL? { url(preferring: ["150x150", "400x300", "600x", "1200x"]) }
        var full: URL? { url(preferring: ["1200x", "600x", "400x300", "150x150"]) }
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
            .compactMap { index, board -> (Int, String, Board)? in
                guard let id = board["id"] as? String else { return nil }
                let media = JSON.object(board, "media")
                return (index, id, Board(
                    name: board["name"] as? String ?? "Untitled board",
                    pinCount: board["pin_count"] as? Int ?? 0,
                    pins: [],
                    coverURL: JSON.firstText(media, "image_cover_url").flatMap(URL.init(string:)),
                    thumbnailURLs: JSON.strings(media["pin_thumbnail_urls"]).compactMap(URL.init(string:))))
            }

        return try await withThrowingTaskGroup(of: (Int, Board).self) { group in
            for (index, id, board) in targets {
                group.addTask {
                    let pinData = try await HTTP.get(
                        URL(string: "\(Self.base)/boards/\(id)/pins?page_size=\(pinsPerBoard)")!,
                        bearer: token)
                    var board = board
                    board.pins = JSON.array(JSON.object(pinData)["items"]).map(Self.pin)
                    return (index, board)
                }
            }
            var collected: [(Int, Board)] = []
            for try await result in group { collected.append(result) }
            return collected.sorted { $0.0 < $1.0 }.map(\.1)   // board order as the API returned it
        }
    }

    /// `media` is a union discriminated by `media_type`; only the image variants
    /// carry `images`. Reading straight through to `images` rather than switching on
    /// the discriminator means video pins simply yield no image instead of needing a
    /// case for every current and future media type.
    private static func pin(_ raw: [String: Any]) -> Pin {
        let sizes = JSON.object(raw, "media", "images").compactMapValues { value -> URL? in
            guard let entry = value as? [String: Any] else { return nil }
            return JSON.firstText(entry, "url").flatMap(URL.init(string:))
        }
        return Pin(title: JSON.firstText(raw, "title", "description", "alt_text") ?? "Untitled pin",
                   image: sizes.isEmpty ? nil : PinImage(sizes: sizes))
    }
}

extension [PinterestProvider.Board] {
    var rows: [Row] {
        guard !isEmpty else { return [Row("No boards", value: "—")] }
        return map { board in
            // `pin_count` is the board's true size, but never report fewer pins than
            // are listed directly beneath it — an absent count would otherwise render
            // "0" above ten visible rows.
            let total = Swift.max(board.pinCount, board.pins.count)
            var children = board.pins.map { Row($0.title) }
            // The value is the whole board while the children are one capped page of
            // it, so without this a 500-pin board looks like it lost 490.
            if total > board.pins.count {
                children.append(Row("+ \(total - board.pins.count) more"))
            }
            return Row(board.name, value: "\(total)", children: children)
        }
    }
}
