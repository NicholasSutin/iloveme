import Foundation

/// Notion. Connected by pasting an internal-integration token rather than by
/// OAuth — the personal shortcut that avoids needing a `client_secret`.
///
/// The only service here with more than one account, because a Notion token is
/// scoped to one workspace: personal and work are separate Notion accounts and so
/// need a token each. That is true of OAuth too, which is why OAuth would not have
/// removed this — see docs/registration.md.
struct NotionProvider: ServiceProvider {
    let kind = ServiceKind.notion

    let config = OAuthConfig(
        clientID: "",          // paste from the portal — see docs/registration.md
        authorize: "https://api.notion.com/v1/oauth/authorize",
        token: "https://api.notion.com/v1/oauth/token",
        scopes: [])   // Notion has capabilities, not scopes

    let connect = ConnectAffordance.pastedToken(prompt: "Integration token")

    /// One card per Notion account. Adding a third is one entry — but the labels are
    /// Keychain keys, so change an existing one only if you mean to orphan its token.
    var accounts: [ServiceAccount] {
        [ServiceAccount(kind, label: "Personal"), ServiceAccount(kind, label: "Work")]
    }

    /// developers.notion.com/reference/versioning
    static let apiVersion = "2026-03-11"

    var placeholderRows: [Row] { [Note]().rows }

    func rows(token: String) async throws -> [Row] {
        try await recentPages(token: token).rows
    }

    // MARK: Data

    struct Note: Sendable {
        var title: String
        var edited: String?
    }

    // MARK: Fetch

    func recentPages(token: String, limit: Int = 5) async throws -> [Note] {
        // Favourites are not exposed by the public API (verified) — most-recently
        // edited is the closest available stand-in.
        let data = try await HTTP.postJSON(
            URL(string: "https://api.notion.com/v1/search")!,
            bearer: token,
            body: ["filter": ["property": "object", "value": "page"],
                   "sort": ["timestamp": "last_edited_time", "direction": "descending"],
                   "page_size": limit],
            headers: ["Notion-Version": Self.apiVersion])

        return JSON.array(JSON.object(data)["results"]).map { page in
            Note(title: Self.title(of: page) ?? "Untitled",
                 edited: (page["last_edited_time"] as? String).map { String($0.prefix(10)) })
        }
    }

    /// The title lives in whichever property has type "title"; which one that is
    /// varies with the page's parent, so this searches rather than indexes.
    private static func title(of page: [String: Any]) -> String? {
        for value in JSON.object(page, "properties").values {
            guard let property = value as? [String: Any],
                  property["type"] as? String == "title" else { continue }
            let text = JSON.array(property["title"])
                .compactMap { $0["plain_text"] as? String }
                .joined()
            if !text.isEmpty { return text }
        }
        return nil
    }
}

extension [NotionProvider.Note] {
    var rows: [Row] {
        isEmpty ? [Row("No pages shared with integration", value: "—")]
                : map { Row($0.title, value: $0.edited) }
    }
}
