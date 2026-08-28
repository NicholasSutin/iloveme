import Foundation

extension Optional {
    /// The house style for "no data": an em dash, never a confident zero.
    /// Shared with the widget so app and Lock Screen agree on what absence looks like.
    ///
    ///     steps.dashed { $0.formatted() }
    func dashed(_ format: (Wrapped) -> String = { "\($0)" }) -> String {
        map(format) ?? "—"
    }
}
