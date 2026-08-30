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
    /// `unauthorized` is what a 401 means *for this caller*. The default suits a
    /// stored token that aged out; a card that just handed over a credential the
    /// user typed says so instead, because "paste a new token" is actively wrong
    /// advice when the field in front of them asks for a secret.
    static func failure(_ error: Error,
                        unauthorized: String = "Token expired — paste a new one") -> ServiceStatus {
        // The chip has room for a few words; a truncated DecodingError is useless
        // for diagnosis, so the whole thing goes to the console. Default privacy,
        // since an upstream error body could in principle carry something sensitive.
        Logger(subsystem: "com.nick.iloveme", category: "service")
            .error("\(String(describing: error))")
        // A 401 body is JSON that says nothing useful once truncated to chip width,
        // and `.failed` is idle, so the paste field is already showing underneath.
        // The chip's whole job is to name which field to fix.
        if let http = error as? HTTPError, http.status == 401 { return .failed(unauthorized) }
        let description = error.localizedDescription
        if description.localizedCaseInsensitiveContains("entitlement") { return .failed("Entitlement missing") }
        if description.localizedCaseInsensitiveContains("authoriz") { return .failed("Not authorized") }
        return .failed(description.count > 40 ? String(description.prefix(40)) + "…" : description)
    }
}
