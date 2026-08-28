import Foundation
import AuthenticationServices
import CryptoKit

/// `ASWebAuthenticationSession` + PKCE for the browser redirect leg.
///
/// Unused today — none of the four providers can complete a redirect flow without
/// a `client_secret` (see `ServiceProvider.connect`). Kept because it is the half
/// of the flow that does not need the Worker proxy, and it is verified working.
@MainActor
final class AuthSession: NSObject {
    private let anchor: ASPresentationAnchor

    init(scene: UIWindowScene) {
        // Every other UIWindow initializer is deprecated on iOS 26, so a session
        // without a scene is not constructible rather than fabricated.
        anchor = scene.keyWindow ?? ASPresentationAnchor(windowScene: scene)
        super.init()
    }

    /// nil when there is no foreground window scene to present from.
    static func current() -> AuthSession? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
            .map(AuthSession.init(scene:))
    }

    /// RFC 7636 verifier/challenge pair.
    static func pkce() -> (verifier: String, challenge: String) {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let verifier = Data(bytes).base64URL
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URL
        return (verifier, challenge)
    }

    /// Presents the provider's consent page. Returns the callback URL together with
    /// the PKCE verifier, which the caller must send to the token endpoint — a
    /// challenge whose verifier was discarded can never be redeemed.
    func authorize(
        config: OAuthConfig,
        extraQuery: [URLQueryItem] = []
    ) async throws -> (callback: URL, verifier: String) {
        guard config.isConfigured else { throw ServiceError.notConfigured }
        let (verifier, challenge) = Self.pkce()

        var components = URLComponents(url: config.authorizationEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "client_id", value: config.clientID),
            .init(name: "redirect_uri", value: "\(config.redirectScheme)://oauth"),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: config.scopes.joined(separator: " ")),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
        ] + extraQuery

        let callback: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: components.url!,
                callbackURLScheme: config.redirectScheme
            ) { url, error in
                if let url { continuation.resume(returning: url) }
                else { continuation.resume(throwing: error ?? ServiceError.notConfigured) }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
        return (callback, verifier)
    }
}

extension AuthSession: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { anchor }
}

extension Data {
    var base64URL: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
