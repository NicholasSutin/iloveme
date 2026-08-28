import Foundation

/// Failures that originate here rather than from the network layer.
enum ServiceError: LocalizedError {
    case notConfigured
    case provider(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Add a client ID"
        case .provider(let message): message
        }
    }
}
