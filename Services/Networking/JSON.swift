import Foundation

/// Tolerant digging into untyped JSON, for the three providers whose responses are
/// too shape-variant to model with `Decodable`. Every miss degrades to empty rather
/// than throwing, which is what the callers want: an absent field becomes "—".
///
/// Parse once with `object(_ data:)`, then read many times.
enum JSON {
    static func object(_ data: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }

    /// Walks nested objects, yielding `[:]` the moment a step is missing.
    /// `JSON.object(root, "data", "viewer", "contributionsCollection")`
    static func object(_ root: [String: Any], _ path: String...) -> [String: Any] {
        path.reduce(root) { $0[$1] as? [String: Any] ?? [:] }
    }

    static func array(_ any: Any?) -> [[String: Any]] { any as? [[String: Any]] ?? [] }

    /// Array of bare strings, as in Pinterest's `pin_thumbnail_urls`. Distinct from
    /// `array(_:)`, which expects objects and would yield `[]` here.
    static func strings(_ any: Any?) -> [String] { any as? [String] ?? [] }

    /// First non-empty string among the given keys, else nil.
    static func firstText(_ object: [String: Any], _ keys: String...) -> String? {
        for key in keys {
            if let text = object[key] as? String, !text.isEmpty { return text }
        }
        return nil
    }
}
