import Foundation

/// Runtime configuration that must not live in a public repository.
///
/// Read from an optional `App/Secrets.plist`, which is gitignored. The file's
/// absence is a supported state: the app builds and runs, and any provider that
/// needs the relay reports itself unavailable rather than failing obscurely.
///
/// The relay token is a speed bump by design (see worker/README.md) — but a speed
/// bump published to a public repo is no speed bump at all, and unlike a binary it
/// can never be un-published from git history.
///
/// Create `App/Secrets.plist` with:
///
///     <dict>
///       <key>RelaySharedToken</key><string>…</string>
///       <key>RelayBaseURL</key><string>https://iloveme.nicholassutin.com</string>
///     </dict>
enum AppSecrets {
    /// Parsed once into concrete strings. Holding the raw `[String: Any]` in a
    /// static would not be Sendable, and nothing here needs the untyped form.
    private struct Values: Sendable {
        var relaySharedToken: String?
        var relayBaseURL: String?
    }

    private static let values: Values = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dictionary = plist as? [String: Any]
        else { return Values() }

        func string(_ key: String) -> String? {
            (dictionary[key] as? String).flatMap { $0.isEmpty ? nil : $0 }
        }
        return Values(relaySharedToken: string("RelaySharedToken"),
                      relayBaseURL: string("RelayBaseURL"))
    }()

    /// Bearer token for the relay Worker. nil when Secrets.plist is absent.
    static var relaySharedToken: String? { values.relaySharedToken }

    /// Defaults to production; override to point the app at staging.
    static var relayBaseURL: URL {
        values.relayBaseURL.flatMap(URL.init(string:))
            ?? URL(string: "https://iloveme.nicholassutin.com")!
    }
}
