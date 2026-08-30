import Foundation

/// The set of service cards, refreshed together.
@MainActor
@Observable
final class Dashboard {
    let services: [ServiceCard]

    /// One card per account, not per service — so a service offering two accounts
    /// contributes two cards, in the order its provider lists them.
    init(accounts: [ServiceAccount] = ServiceKind.allCases.flatMap { $0.provider.accounts }) {
        services = accounts.map(ServiceCard.init)
    }

    /// A task group rather than loose `Task`s: same concurrency, but cancellation
    /// reaches the in-flight requests when the view goes away or a pull is aborted.
    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for service in services { group.addTask { await service.load() } }
        }
    }
}
