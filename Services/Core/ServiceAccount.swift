import Foundation

/// One connectable account within a service.
///
/// Most services get exactly one, unlabelled, and behave exactly as they did before
/// this type existed. Notion gets two: personal and work are separate Notion
/// accounts, and Notion scopes every credential to a single workspace, so two
/// workspaces means two tokens whichever auth flow is used — OAuth would not merge
/// them either. See docs/registration.md.
///
/// The label is part of the Keychain account name, so it is an identifier as much as
/// a caption. Renaming one orphans the token stored under the old name: that card
/// simply reads as "Not connected" again, and pasting the token back fixes it.
struct ServiceAccount: Identifiable, Hashable, Sendable {
    let kind: ServiceKind

    /// nil for a service the user can only hold one login for.
    let label: String?

    init(_ kind: ServiceKind, label: String? = nil) {
        self.kind = kind
        self.label = label
    }

    /// Keychain account name, and SwiftUI identity for the card.
    ///
    /// An unlabelled account keeps the bare `kind.rawValue` that predates labels, so
    /// credentials already in the Keychain — GitHub's token, Pinterest's secret —
    /// are found where they were left and nothing has to be reconnected.
    var id: String { label.map { "\(kind.rawValue)/\($0)" } ?? kind.rawValue }

    /// The card's heading. Only a labelled account has to say which one it is.
    var title: String { label.map { "\(kind.title) · \($0)" } ?? kind.title }
}
