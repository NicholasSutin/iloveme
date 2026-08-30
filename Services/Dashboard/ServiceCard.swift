import Foundation

/// One card's state. Provider-agnostic: everything service-specific is reached
/// through `kind.provider`, so this file does not change when an integration is
/// added.
///
/// A card is one *account*, not one service. Services with a single login are
/// unaffected; Notion has two, and they are two independent cards that happen to
/// share a provider.
@MainActor
@Observable
final class ServiceCard: Identifiable {
    let account: ServiceAccount
    private(set) var status: ServiceStatus
    private(set) var rows: [Row]

    /// Set for the life of a device-flow prompt, nil otherwise. One field, because
    /// the code and its verification URL are never meaningful apart.
    private(set) var deviceCode: GitHubDeviceFlow.DeviceCode?

    /// Held so a prompt that is abandoned does not leave a 15-minute poll running.
    private var connectTask: Task<Void, Never>?

    nonisolated var id: String { account.id }

    nonisolated var kind: ServiceKind { account.kind }

    private var provider: any ServiceProvider { kind.provider }

    /// What a 401 means here, in terms of the field the user is looking at. A
    /// `.clientCredentials` card has no token field to point them at — the secret
    /// is what it holds, so the secret is what a rejection is about.
    private var unauthorizedHint: String {
        switch provider.connect {
        case .clientCredentials: "Secret rejected — check it"
        default: "Token expired — paste a new one"
        }
    }

    init(account: ServiceAccount) {
        self.account = account
        self.rows = account.kind.provider.placeholderRows
        self.status = TokenStore.shared.hasToken(for: account)
            ? .connected("Connected")
            : account.kind.provider.idleStatus
    }

    // MARK: Refresh

    func load() async {
        guard TokenStore.shared.hasToken(for: account) else {
            status = provider.idleStatus
            return
        }
        status = .connecting

        do {
            guard let token = try await currentToken() else {
                status = provider.idleStatus
                return
            }
            rows = try await provider.rows(token: token.accessToken)
            status = .updatedNow()
        } catch is CancellationError {
            status = provider.idleStatus
        } catch {
            status = .failure(error, unauthorized: unauthorizedHint)
        }
    }

    /// The stored token, renewed first if it has expired and the provider can renew
    /// without the user. This is what finally uses `OAuthToken.isExpired`.
    ///
    /// A provider that cannot renew gets its expired token back unchanged, so the
    /// resulting 401 still surfaces as "Token expired — paste a new one" rather than
    /// being pre-empted by a vaguer message here.
    private func currentToken() async throws -> OAuthToken? {
        let stored = TokenStore.shared.token(for: account)
        if let stored, !stored.isExpired { return stored }
        guard case .clientCredentials = provider.connect,
              let secret = TokenStore.shared.clientSecret(for: account) else { return stored }

        let minted = try await ClientCredentialsFlow(config: provider.config).token(secret: secret)
        try TokenStore.shared.saveToken(minted, for: account)
        return minted
    }

    // MARK: Connect

    /// `.pastedToken` path: the user brings a token from the provider. Overwrites
    /// whatever is stored, so replacing an expired token needs no disconnect first.
    func savePastedToken(_ raw: String) async {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try TokenStore.shared.saveToken(OAuthToken(accessToken: trimmed), for: account)
            await load()
        } catch {
            status = .failure(error, unauthorized: unauthorizedHint)
        }
    }

    /// `.clientCredentials` path: the user brings the app secret once, and the app
    /// mints its own tokens from it from then on.
    ///
    /// Minting before storing doubles as validation — a mistyped secret fails here,
    /// visibly, instead of being persisted and failing on every later load.
    func saveClientSecret(_ raw: String) async {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Sending a token to the token endpoint as if it were a secret would fail
        // with an authentication error that blamed the wrong thing entirely.
        guard !provider.isAccessToken(trimmed) else {
            await savePastedToken(trimmed)
            return
        }
        status = .connecting
        do {
            let token = try await ClientCredentialsFlow(config: provider.config).token(secret: trimmed)
            try TokenStore.shared.saveClientSecret(trimmed, for: account)
            try TokenStore.shared.saveToken(token, for: account)
            await load()
        } catch {
            status = .failure(error, unauthorized: unauthorizedHint)
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
            try TokenStore.shared.saveToken(token, for: account)
            deviceCode = nil
            await load()
        } catch is CancellationError {
            status = provider.idleStatus
        } catch {
            status = .failure(error, unauthorized: unauthorizedHint)
        }
    }

    func disconnect() {
        connectTask?.cancel()
        TokenStore.shared.clearToken(for: account)
        // Otherwise "disconnect" would leave the credential that mints tokens behind,
        // and the next load would silently reconnect.
        TokenStore.shared.clearClientSecret(for: account)
        rows = provider.placeholderRows
        status = provider.idleStatus
    }
}
