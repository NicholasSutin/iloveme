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
        let description = error.localizedDescription
        if description.localizedCaseInsensitiveContains("entitlement") { return .failed("Entitlement missing") }
        if description.localizedCaseInsensitiveContains("authoriz") { return .failed("Not authorized") }
        return .failed(description.count > 40 ? String(description.prefix(40)) + "…" : description)
    }
}
