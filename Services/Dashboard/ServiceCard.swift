import Foundation

/// One card's state. Provider-agnostic: everything service-specific is reached
/// through `kind.provider`, so this file does not change when an integration is
/// added.
@MainActor
@Observable
final class ServiceCard: Identifiable {
    let kind: ServiceKind
    private(set) var status: ServiceStatus
    private(set) var rows: [Row]

    /// Set for the life of a device-flow prompt, nil otherwise. One field, because
    /// the code and its verification URL are never meaningful apart.
    private(set) var deviceCode: GitHubDeviceFlow.DeviceCode?

    /// Held so a prompt that is abandoned does not leave a 15-minute poll running.
    private var connectTask: Task<Void, Never>?

    nonisolated var id: String { kind.rawValue }

    private var provider: any ServiceProvider { kind.provider }

    init(kind: ServiceKind) {
        self.kind = kind
        self.rows = kind.provider.placeholderRows
        self.status = TokenStore.shared.hasToken(for: kind)
            ? .connected("Connected")
            : kind.provider.idleStatus
    }

    // MARK: Refresh

    func load() async {
        guard let token = TokenStore.shared.token(for: kind) else {
            status = provider.idleStatus
            return
        }
        status = .connecting

        do {
            rows = try await provider.rows(token: token.accessToken)
            status = .updatedNow()
        } catch is CancellationError {
            status = provider.idleStatus
        } catch {
            status = .failure(error)
        }
    }

    // MARK: Connect

    /// `.pastedToken` path: the user brings a long-lived token from the provider.
    func savePastedToken(_ raw: String) async {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try TokenStore.shared.saveToken(OAuthToken(accessToken: trimmed), for: kind)
            await load()
        } catch {
            status = .failure(error)
        }
    }

    /// `.deviceFlow` path. Replaces any prompt already in flight, so tapping
    /// Connect twice cannot leave two pollers racing to write this card.
    func connectDeviceFlow() {
        connectTask?.cancel()
        connectTask = Task { [weak self] in await self?.runDeviceFlow() }
    }

    func cancelConnect() {
        connectTask?.cancel()
        connectTask = nil
        deviceCode = nil
        status = provider.idleStatus
    }

    private func runDeviceFlow() async {
        let config = provider.config
        guard config.isConfigured else { status = .notConfigured; return }
        status = .connecting
        defer { deviceCode = nil }
        do {
            let flow = GitHubDeviceFlow(config: config)
            let code = try await flow.requestCode()
            deviceCode = code
            let token = try await flow.waitForToken(code)
            try TokenStore.shared.saveToken(token, for: kind)
            deviceCode = nil
            await load()
        } catch is CancellationError {
            status = provider.idleStatus
        } catch {
            status = .failure(error)
        }
    }

    func disconnect() {
        connectTask?.cancel()
        TokenStore.shared.clearToken(for: kind)
        rows = provider.placeholderRows
        status = provider.idleStatus
    }
}
