import Foundation

/// The registry. One switch, exhaustive on purpose: a new `ServiceKind` is a
/// compile error here rather than a runtime miss from a dictionary lookup.
///
/// Instances are cached because constructing an `OAuthConfig` parses its URLs, and
/// `kind.provider` is read from view bodies.
enum Providers {
    private static let strava = StravaProvider()
    private static let notion = NotionProvider()
    private static let pinterest = PinterestProvider()
    private static let github = GitHubProvider()

    static func provider(for kind: ServiceKind) -> any ServiceProvider {
        switch kind {
        case .strava: strava
        case .notion: notion
        case .pinterest: pinterest
        case .github: github
        }
    }
}

extension ServiceKind {
    /// The behaviour behind this case. Sugar for `Providers.provider(for:)`.
    var provider: any ServiceProvider { Providers.provider(for: self) }
}
