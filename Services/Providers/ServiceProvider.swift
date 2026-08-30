import Foundation

/// How a service is connected. The model picks the shape; the view renders it.
/// A new paste-a-token integration therefore costs zero view code.
enum ConnectAffordance: Sendable {
    /// RFC 8628 device flow — no secret, no redirect leg.
    case deviceFlow
    /// Browser consent, then the code is exchanged through the relay Worker.
    /// Used where the provider demands a client_secret we refuse to embed.
    case webRedirect
    /// The user pastes a long-lived token they generated on the provider's site.
    case pastedToken(prompt: String)
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

    /// Shown before the first successful fetch, and whenever a fetch returns
    /// nothing. One definition, so the empty state cannot drift from the loaded one.
    var placeholderRows: [Row] { get }

    /// Fetch and render in one step. Implementations stay off the main actor.
    func rows(token: String) async throws -> [Row]

    /// Whether token exchange and refresh must route through the relay Worker.
    /// True where the provider demands a client_secret. Kept explicit rather than
    /// inferred from `connect`, since a future provider could use a browser
    /// redirect without needing a secret.
    var usesRelay: Bool { get }
}

extension ServiceProvider {
    var usesRelay: Bool { false }

    /// Most providers are plain OAuth apps that need a client ID compiled in.
    var isConnectable: Bool {
        switch connect {
        case .pastedToken: true          // the user brings their own credential
        case .deviceFlow: config.isConfigured
        // Needs both a client ID and a relay to exchange the code against.
        case .webRedirect: config.isConfigured && TokenRelay.configured != nil
        case .unavailable: false
        }
    }

    /// Status to show whenever no token is stored.
    var idleStatus: ServiceStatus { isConnectable ? .disconnected : .notConfigured }
}
