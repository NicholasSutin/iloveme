import Foundation

/// How a service is connected. The model picks the shape; the view renders it.
/// A new paste-a-token integration therefore costs zero view code.
enum ConnectAffordance: Sendable {
    /// RFC 8628 device flow — no secret, no redirect leg.
    case deviceFlow
    /// The user pastes a token they generated on the provider's site. It may or
    /// may not expire — Notion's does not, Pinterest's does — so the paste field
    /// stays reachable from `.failed`, which `ServiceStatus.isIdle` guarantees.
    case pastedToken(prompt: String)
    /// The user pastes the app's own client secret once; the app then mints and
    /// renews its own tokens from it, with no further interaction. Only honest
    /// where the app owner and the user are the same person.
    case clientCredentials(prompt: String)
    /// Cannot be connected from the device at all, with the reason to show.
    case unavailable(reason: String)
}

/// Everything one integration knows about itself: where it lives, how it is
/// connected, how to fetch it, and how its data becomes rows.
///
/// **Adding an integration is two edits.** Write one file conforming to this, then
/// add a `ServiceKind` case; the compiler demands the registry entry that joins
/// them. Nothing else in the app changes — the dashboard, the card view and the
/// connect controls are all written against this protocol.
protocol ServiceProvider: Sendable {
    var kind: ServiceKind { get }
    var config: OAuthConfig { get }
    var connect: ConnectAffordance { get }

    /// The accounts this service offers, in display order — one card each.
    ///
    /// Defaulted to a single unlabelled account, which is what every service that a
    /// person only has one login for should use. Override it only when they can
    /// genuinely hold more than one, as with Notion's separate personal and work
    /// accounts. Each account connects, fails and disconnects on its own.
    var accounts: [ServiceAccount] { get }

    /// Shown before the first successful fetch, and whenever a fetch returns
    /// nothing. One definition, so the empty state cannot drift from the loaded one.
    var placeholderRows: [Row] { get }

    /// Fetch and render in one step. Implementations stay off the main actor.
    func rows(token: String) async throws -> [Row]
}

extension ServiceProvider {
    /// One login, no label — the shape of every service except Notion.
    var accounts: [ServiceAccount] { [ServiceAccount(kind)] }

    /// Most providers are plain OAuth apps that need a client ID compiled in.
    var isConnectable: Bool {
        switch connect {
        case .pastedToken: true          // the user brings their own credential
        case .deviceFlow, .clientCredentials: config.isConfigured
        case .unavailable: false
        }
    }

    /// Status to show whenever no token is stored.
    var idleStatus: ServiceStatus { isConnectable ? .disconnected : .notConfigured }
}
