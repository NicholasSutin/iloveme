import Foundation
import Security

/// Keychain-backed token storage. No network involved.
struct TokenStore: Sendable {
    static let shared = TokenStore(service: "com.nick.iloveme.oauth")

    let service: String

    private func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    // MARK: Raw string access

    func save(_ token: String, account: String) throws {
        var q = query(account)
        SecItemDelete(q as CFDictionary)
        q[kSecValueData as String] = Data(token.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(q as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    func read(account: String) -> String? {
        var q = query(account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    /// Presence only — no payload returned, nothing to decode.
    func exists(account: String) -> Bool {
        var q = query(account)
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        return SecItemCopyMatching(q as CFDictionary, nil) == errSecSuccess
    }

    func delete(account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }

    // MARK: Tokens, keyed by account

    // Keying by `ServiceAccount` rather than `ServiceKind` is what lets one service
    // hold several logins at once: two Notion accounts are two Keychain entries that
    // never see each other. An unlabelled account's key is unchanged, so this is not
    // a migration — nothing already stored moves.

    func saveToken(_ token: OAuthToken, for account: ServiceAccount) throws {
        let data = try JSONEncoder().encode(token)
        try save(String(decoding: data, as: UTF8.self), account: account.id)
    }

    func token(for account: ServiceAccount) -> OAuthToken? {
        guard let raw = read(account: account.id) else { return nil }
        return try? JSONDecoder().decode(OAuthToken.self, from: Data(raw.utf8))
    }

    /// Existence check that skips returning and decoding the payload — the launch
    /// path only needs to know whether a card starts connected.
    func hasToken(for account: ServiceAccount) -> Bool { exists(account: account.id) }

    func clearToken(for account: ServiceAccount) { delete(account: account.id) }

    // MARK: Client secrets, for providers that mint their own tokens

    /// Stored under a distinct account so the token can be replaced on every mint
    /// without disturbing the secret that produced it.
    ///
    /// This is the only copy: `.clientCredentials` providers keep their secret here
    /// rather than in the app binary or an xcconfig, so it is absent from the repo,
    /// absent from the build, and removed with the rest of the account by
    /// `disconnect()`.
    private func secretAccount(_ account: ServiceAccount) -> String { "\(account.id).secret" }

    func saveClientSecret(_ secret: String, for account: ServiceAccount) throws {
        try save(secret, account: secretAccount(account))
    }

    func clientSecret(for account: ServiceAccount) -> String? { read(account: secretAccount(account)) }

    func clearClientSecret(for account: ServiceAccount) { delete(account: secretAccount(account)) }
}

struct KeychainError: LocalizedError {
    let status: OSStatus
    var errorDescription: String? { "Keychain error \(status)" }
}
