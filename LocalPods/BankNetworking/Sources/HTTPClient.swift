import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum APIError: Error, Equatable {
    case invalidResponse
    case status(Int)
    case decoding
    case offline
}

public struct Endpoint: Sendable {
    public enum Method: String, Sendable { case get = "GET", post = "POST" }

    public let path: String
    public let method: Method
    public let body: Data?
    public let headers: [String: String]

    public init(path: String, method: Method = .get, body: Data? = nil, headers: [String: String] = [:]) {
        self.path = path
        self.method = method
        self.body = body
        self.headers = headers
    }
}

public protocol HTTPClient: Sendable {
    func send(_ endpoint: Endpoint) async throws -> Data
}

public final class URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: @Sendable () -> String?

    public init(baseURL: URL, session: URLSession = .shared, tokenProvider: @escaping @Sendable () -> String? = { nil }) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
    }

    public func send(_ endpoint: Endpoint) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = tokenProvider() { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where [.notConnectedToInternet, .networkConnectionLost, .timedOut].contains(error.code) {
            throw APIError.offline
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.status(http.statusCode) }
        return data
    }
}
