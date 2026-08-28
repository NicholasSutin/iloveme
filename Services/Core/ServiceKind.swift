import Foundation

/// The set of integrations. Kept as an enum rather than a registry key so that
/// adding one is a compile error everywhere it matters — and so the raw value can
/// serve as the Keychain account name.
///
/// Everything behavioural (endpoints, fetching, rendering, how to connect) lives
/// on the matching `ServiceProvider`, not here. This type holds only what the
/// chrome needs.
enum ServiceKind: String, CaseIterable, Identifiable, Sendable {
    case strava, notion, pinterest, github

    var id: String { rawValue }

    var title: String {
        switch self {
        case .strava: "Strava"
        case .notion: "Notion"
        case .pinterest: "Pinterest"
        case .github: "GitHub"
        }
    }

    var symbol: String {
        switch self {
        case .strava: "figure.run"
        case .notion: "note.text"
        case .pinterest: "square.grid.2x2"
        case .github: "chevron.left.forwardslash.chevron.right"
        }
    }
}
