import Foundation

/// Pinterest. Blocked on the Worker proxy: token exchange requires a
/// `client_secret` we refuse to embed in the app.
struct PinterestProvider: ServiceProvider {
    let kind = ServiceKind.pinterest

    let config = OAuthConfig(
        clientID: "",          // paste from the portal — see docs/registration.md
        authorize: "https://www.pinterest.com/oauth/",
        token: "https://api.pinterest.com/v5/oauth/token",
        scopes: ["boards:read", "pins:read"])

    let connect = ConnectAffordance.unavailable(
        reason: "Token exchange requires the Worker proxy (not built yet)")

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

    /// Trial tier allows 1,000 requests/day in total, so the fan-out is capped to
    /// keep 15-minute polling inside budget. The cap bounds the request *count*;
    /// fetching concurrently only changes when they are issued.
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
