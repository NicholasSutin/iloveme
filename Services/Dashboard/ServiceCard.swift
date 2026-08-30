import AuthenticationServices
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

    /// ASWebAuthenticationSession holds its presentation context provider weakly,
    /// so the AuthSession must be owned here for the life of the browser flow.
    private var authSession: AuthSession?

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
        guard var token = TokenStore.shared.token(for: kind) else {
            status = provider.idleStatus
            return
        }
        status = .connecting

        // Strava access tokens live ~6 hours, so refresh proactively rather than
        // waiting for a 401 and showing the user an error we could have avoided.
        if token.isExpired, provider.usesRelay, let refreshToken = token.refreshToken {
            guard let relay = TokenRelay.configured else {
                status = .failed("Relay not configured")
                return
            }
            do {
                token = try await relay.refresh(refreshToken, provider: kind)
                try TokenStore.shared.saveToken(token, for: kind)
            } catch {
                status = .failure(error)
                return
            }
        }

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

    /// `.webRedirect` path: browser consent, then the code is exchanged through
    /// the relay Worker because the provider requires a client_secret.
    func connectWebRedirect() {
        connectTask?.cancel()
        connectTask = Task { [weak self] in await self?.runWebRedirect() }
    }

    private func runWebRedirect() async {
        let config = provider.config
        guard config.isConfigured else { status = .notConfigured; return }
        guard let relay = TokenRelay.configured else {
            status = .failed("Relay not configured")
            return
        }
        guard let session = AuthSession.current() else {
            status = .failed("No window to present from")
            return
        }
        authSession = session
        status = .connecting
        defer { authSession = nil }

        do {
            // The PKCE verifier is returned but unused here: Strava documents no
            // PKCE support, and the relay's client_secret is what secures exchange.
            let (callback, _) = try await session.authorize(config: config)
            let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems
            guard let code = items?.first(where: { $0.name == "code" })?.value else {
                let denial = items?.first(where: { $0.name == "error" })?.value
                throw ServiceError.provider(denial ?? "No authorization code returned")
            }
            let token = try await relay.exchange(code: code, provider: kind)
            try TokenStore.shared.saveToken(token, for: kind)
            await load()
        } catch is CancellationError {
            status = provider.idleStatus
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // Dismissing the sheet is a choice, not a failure.
            status = provider.idleStatus
        } catch {
            status = .failure(error)
        }
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
