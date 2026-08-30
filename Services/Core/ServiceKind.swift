import Foundation

/// The set of integrations. Kept as an enum rather than a registry key so that
/// adding one is a compile error everywhere it matters — and so the raw value can
/// seed the Keychain account name, which `ServiceAccount.id` builds on.
///
/// Everything behavioural (endpoints, fetching, rendering, how to connect) lives
/// on the matching `ServiceProvider`, not here. This type holds only what the
/// chrome needs.
enum ServiceKind: String, CaseIterable, Identifiable, Sendable {
    case notion, pinterest, github

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notion: "Notion"
        case .pinterest: "Pinterest"
        case .github: "GitHub"
        }
    }

    var symbol: String {
        switch self {
        case .notion: "note.text"
        case .pinterest: "square.grid.2x2"
        case .github: "chevron.left.forwardslash.chevron.right"
        }
    }
}
