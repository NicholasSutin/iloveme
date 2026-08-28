import Foundation

enum AppGroup {
    static let id = "group.com.nick.iloveme"
    /// Computed, not stored: `UserDefaults` is not `Sendable`, and Foundation
    /// already caches suite instances internally, so there is nothing to gain.
    static var defaults: UserDefaults? { UserDefaults(suiteName: id) }
}

/// Written by the app, read by the widget. The widget never touches HealthKit
/// directly — HealthKit is encrypted while the device is locked, which is exactly
/// when Lock Screen widgets render.
struct StepSnapshot: Codable {
    var steps: Int
    var updated: Date

    private static let key = "stepSnapshot"

    static func load() -> StepSnapshot? {
        guard let data = AppGroup.defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(StepSnapshot.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults?.set(data, forKey: Self.key)
    }
}
