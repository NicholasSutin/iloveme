import Foundation

/// The set of service cards, refreshed together.
@MainActor
@Observable
final class Dashboard {
    let services: [ServiceCard]

    init(kinds: [ServiceKind] = ServiceKind.allCases) {
        services = kinds.map(ServiceCard.init)
    }

    /// A task group rather than loose `Task`s: same concurrency, but cancellation
    /// reaches the in-flight requests when the view goes away or a pull is aborted.
    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for service in services { group.addTask { await service.load() } }
        }
    }
}
