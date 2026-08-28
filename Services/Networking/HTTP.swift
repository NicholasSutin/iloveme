import Foundation

struct HTTPError: LocalizedError {
    let status: Int
    let body: String
    var errorDescription: String? { "HTTP \(status): \(body.prefix(200))" }
}

/// The single outbound path. Every request in the app funnels through `send`, so
/// retries, timeouts, logging and auth headers each have exactly one home — and
/// every failure keeps its status code and body.
enum HTTP {
    static func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw HTTPError(status: status, body: String(decoding: data, as: UTF8.self))
        }
        return data
    }

    static func get(_ url: URL, bearer: String, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        return try await send(request)
    }

    static func postJSON(_ url: URL, bearer: String, body: [String: Any],
                         headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await send(request)
    }

    /// Form-encoded POST body. Split out from `TokenExchange` because the device
    /// flow needs the raw response on a 200 that carries `{"error": …}`.
    static func form(_ url: URL, params: [String: String], headers: [String: String] = [:]) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .unreservedRFC3986) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        return request
    }
}

extension CharacterSet {
    /// RFC 3986 unreserved. `.alphanumerics` would escape the `-` and `_` inside
    /// values like `urn:ietf:params:oauth:grant-type:device_code`, which providers
    /// compare as literal strings.
    static let unreservedRFC3986 = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}
