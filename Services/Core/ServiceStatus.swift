import OSLog
import SwiftUI

/// What a card's status chip shows. Purely a display type — it carries a string
/// and a colour, not a state machine. The factories below exist so that every
/// chip on screen phrases the same situation the same way.
enum ServiceStatus: Equatable, Sendable {
    case notConfigured          // nothing to connect with yet
    case disconnected           // connectable, no token stored
    case connecting
    case connected(String)      // detail, e.g. "Updated 12:04"
    case failed(String)

    var label: String {
        switch self {
        case .notConfigured: "Not configured"
        case .disconnected:  "Not connected"
        case .connecting:    "Connecting…"
        case .connected(let detail): detail
        case .failed(let message): message
        }
    }

    var tint: Color {
        switch self {
        case .notConfigured: .secondary
        case .disconnected:  .orange
        case .connecting:    .blue
        case .connected:     .green
        case .failed:        .red
        }
    }

    /// True while the card has no data worth showing, i.e. the user may want to
    /// act. Drives whether connect controls appear.
    var isIdle: Bool {
        switch self {
        case .notConfigured, .disconnected, .failed: true
        case .connecting, .connected: false
        }
    }

    /// The one "just refreshed" detail string.
    static func updatedNow() -> ServiceStatus {
        .connected("Updated \(Date().formatted(date: .omitted, time: .shortened))")
    }

    /// The one error-to-chip rule. Apple's messages are full sentences; a chip has
    /// room for a few words, and the common HealthKit failures deserve real names.
    static func failure(_ error: Error) -> ServiceStatus {
        // The chip has room for a few words; a truncated DecodingError is useless
        // for diagnosis, so the whole thing goes to the console. Default privacy,
        // since an upstream error body could in principle carry something sensitive.
        Logger(subsystem: "com.nick.iloveme", category: "service")
            .error("\(String(describing: error))")
        // Pinterest's tokens expire by design, so 401 is a routine state here, not
        // an anomaly — and its body is JSON that says nothing useful once truncated
        // to chip width. `.failed` is idle, so the paste field is already showing
        // underneath: the chip only has to say which field to fill.
        if let http = error as? HTTPError, http.status == 401 { return .failed("Token expired — paste a new one") }
        let description = error.localizedDescription
        if description.localizedCaseInsensitiveContains("entitlement") { return .failed("Entitlement missing") }
        if description.localizedCaseInsensitiveContains("authoriz") { return .failed("Not authorized") }
        return .failed(description.count > 40 ? String(description.prefix(40)) + "…" : description)
    }
}
