import SwiftUI

/// The card footer: whatever the user can do about this service right now.
/// Which control appears is decided by the provider's `ConnectAffordance`, so a
/// new paste-a-token integration needs no changes here.
struct ConnectControls: View {
    let card: ServiceCard

    var body: some View {
        if let code = card.deviceCode {
            DeviceCodePrompt(code: code, onCancel: card.cancelConnect)
        } else if card.status.isIdle {
            affordance
        }
    }

    @ViewBuilder
    private var affordance: some View {
        let provider = card.kind.provider
        switch provider.connect {
        case .deviceFlow:
            // Without a client ID there is nothing to connect to; the "Not
            // configured" chip already says so, so no dead button.
            if provider.config.isConfigured {
                Button("Connect") { card.connectDeviceFlow() }
                    .font(.subheadline)
                    .buttonStyle(.bordered)
            }
        case .pastedToken(let prompt):
            PastedSecretField(prompt: prompt) { await card.savePastedToken($0) }
        case .clientCredentials(let prompt):
            PastedSecretField(prompt: prompt) { await card.saveClientSecret($0) }
        case .unavailable(let reason):
            Text(reason)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

/// Owns the in-progress text, so the cards that never paste anything do not each
/// carry an empty string of state. Takes a closure rather than a `ServiceCard`
/// because what a pasted string *means* differs by affordance — an access token for
/// `.pastedToken`, an app secret for `.clientCredentials` — while the field itself
/// is identical.
private struct PastedSecretField: View {
    let prompt: String
    let save: (String) async -> Void
    @State private var token = ""

    var body: some View {
        HStack(spacing: Theme.rowGap) {
            SecureField(prompt, text: $token)
                .font(.subheadline)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Save") {
                Task { await save(token); token = "" }
            }
            .font(.subheadline)
            .buttonStyle(.bordered)
            .disabled(token.isEmpty)
        }
    }
}

private struct DeviceCodePrompt: View {
    let code: GitHubDeviceFlow.DeviceCode
    let onCancel: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Enter this code on GitHub:")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Text(code.userCode)
                    .font(.title3.monospaced().bold())
                    .textSelection(.enabled)
                Button("Open GitHub") {
                    if let url = code.verificationURL { openURL(url) }
                }
                .font(.subheadline)
                .buttonStyle(.borderedProminent)
                Button("Cancel", action: onCancel)
                    .font(.subheadline)
                    .buttonStyle(.bordered)
            }
        }
    }
}
