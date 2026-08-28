import Foundation

/// The one display primitive. Every integration, whatever its API returns, is
/// reduced to label/value text — which is why the card views never need to know
/// which service they are rendering.
///
/// `children` covers one level of nesting (a Pinterest board and its pins).
/// Deliberately no stored identity: rows are positional within a card, and views
/// key on the index. A per-instance UUID would re-key every row on every refresh,
/// tearing down the view tree and collapsing open disclosure groups.
struct Row: Sendable, Equatable {
    var label: String
    var value: String?
    var children: [Row]

    init(_ label: String, value: String? = nil, children: [Row] = []) {
        self.label = label
        self.value = value
        self.children = children
    }
}
