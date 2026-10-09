//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

// Nested in `Logger_Tests` so it never runs alongside the tests that replace `LogConfig.logger`.
extension Logger_Tests {
    @Suite
    struct URLSessionTransport_Tests {
        @Test func successfulRequestIsLoggedOnceAtDebugLevel() async throws {
            let body = Data(#"{"duration":"1ms"}"#.utf8)
            let (transport, destination) = makeTransport(statusCode: 200, body: body)
            defer { LogConfig.reset() }

            _ = try await transport.execute(request: makeRequest(path: "/api/v2/feeds"))

            let details = try await destination.waitForSingleDetails()
            #expect(details.level == .debug)
            #expect(details.message == "200 GET /api/v2/feeds")
            #expect(details.subsystem == .httpRequests)
            let attachment = try #require(details.attachment as? HTTPLogAttachment)
            #expect(attachment.responseBody == body)
            #expect(attachment.error == nil)
            #expect(attachment.logDescription.contains("curl"))
        }

        @Test func failedRequestIsLoggedOnceAtErrorLevel() async throws {
            let body = Data(#"{"code":4,"message":"Invalid input","StatusCode":400,"duration":"","more_info":"","details":[]}"#.utf8)
            let (transport, destination) = makeTransport(statusCode: 400, body: body)
            defer { LogConfig.reset() }

            await #expect(throws: APIError.self) {
                try await transport.execute(request: makeRequest(path: "/api/v2/feeds"))
            }

            let details = try await destination.waitForSingleDetails()
            #expect(details.level == .error)
            #expect(details.message == "400 GET /api/v2/feeds")
            let attachment = try #require(details.attachment as? HTTPLogAttachment)
            #expect(attachment.error is APIError)
            #expect(attachment.responseBody == body)
        }

        @Test func expiredTokenIsLoggedAtInfoLevel() async throws {
            let (transport, destination) = makeTransport(statusCode: 401, body: expiredTokenBody)
            defer { LogConfig.reset() }

            await #expect(throws: APIError.self) {
                try await transport.execute(request: makeRequest(path: "/api/v2/feeds"))
            }

            let details = try await destination.waitForSingleDetails()
            #expect(details.level == .info)
            #expect(details.message == "401 GET /api/v2/feeds")
        }

        @Test func expiredTokenIsRefreshedAndBothAttemptsAreLogged() async throws {
            let (transport, destination) = makeTransport(
                responses: [
                    .http(statusCode: 401, body: expiredTokenBody),
                    .http(statusCode: 200, body: Data(#"{"ok":true}"#.utf8))
                ],
                tokenProvider: { $0(.success(UserToken(rawValue: "refreshed-token"))) }
            )
            defer { LogConfig.reset() }
            let updatedToken = TokenBox()
            transport.setTokenUpdater { updatedToken.value = $0.rawValue }
            let ready = Date().addingTimeInterval(2)
            while transport.onTokenUpdate == nil, Date() < ready {
                try await Task.sleep(nanoseconds: 10_000_000)
            }

            _ = try await transport.execute(request: makeRequest(path: "/api/v2/feeds"))

            let details = try await destination.waitForDetails(count: 3)
            #expect(details.map(\.level) == [.info, .debug, .debug])
            #expect(details.map(\.message) == [
                "401 GET /api/v2/feeds",
                "Refreshing user token",
                "200 GET /api/v2/feeds"
            ])
            #expect(StubURLProtocol.requests.count == 2)
            #expect(StubURLProtocol.requests[1].value(forHTTPHeaderField: "authorization") == "refreshed-token")
            #expect(updatedToken.value == "refreshed-token")
        }

        @Test func failedTokenRefreshIsLoggedAndThrown() async throws {
            let (transport, destination) = makeTransport(
                responses: [.http(statusCode: 401, body: expiredTokenBody)],
                tokenProvider: { completion in
                    completion(.failure(APIError(code: 4, message: "Refresh failed", statusCode: 400)))
                }
            )
            defer { LogConfig.reset() }

            await #expect(throws: APIError.self) {
                try await transport.execute(request: makeRequest(path: "/api/v2/feeds"))
            }

            let details = try await destination.waitForDetails(count: 2)
            #expect(details.map(\.level) == [.info, .debug])
            #expect(details.map(\.message) == ["401 GET /api/v2/feeds", "Refreshing user token"])
            #expect(StubURLProtocol.requests.count == 1)
        }

        @Test func cancelledRequestIsLoggedAtInfoLevelForEveryAttempt() async throws {
            try await assertRetriedTransportFailure(.cancelled, level: .info)
        }

        @Test func timedOutRequestIsLoggedAtErrorLevelForEveryAttempt() async throws {
            try await assertRetriedTransportFailure(.timedOut, level: .error)
        }

        @Test func unreadableErrorResponseIsLoggedAtErrorLevel() async throws {
            let (transport, destination) = makeTransport(
                responses: [.http(statusCode: 400, body: Data("not-json".utf8))]
            )
            defer { LogConfig.reset() }

            await #expect(throws: ClientError.NetworkError.self) {
                try await transport.execute(request: makeRequest(path: "/api/v2/feeds"))
            }

            // A response that cannot be decoded is not an API error, so the request is retried.
            let details = try await destination.waitForDetails(count: 4)
            #expect(details.allSatisfy { $0.level == .error && $0.message == "400 GET /api/v2/feeds" })
            let attachment = try #require(details[0].attachment as? HTTPLogAttachment)
            #expect(attachment.error is ClientError.NetworkError)
        }

        @Test func responseWithoutStatusCodeIsLoggedAsFailed() async throws {
            let (transport, destination) = makeTransport(responses: [.nonHTTP(Data("ok".utf8))])
            defer { LogConfig.reset() }

            _ = try await transport.execute(request: makeRequest(path: "/api/v2/feeds"))

            let details = try await destination.waitForSingleDetails()
            #expect(details.level == .debug)
            #expect(details.message == "FAILED GET /api/v2/feeds")
        }

        @Test func openAPIRequestSendsClientHeadersAndIsLoggedOnce() async throws {
            let (transport, destination) = makeTransport(statusCode: 200, body: Data("{}".utf8))
            defer { LogConfig.reset() }
            let request = Request(
                url: try #require(URL(string: "https://stream.test/api/v2/feeds")),
                method: .post,
                queryParams: [],
                headers: [:]
            )

            _ = try await transport.execute(request: request)

            let details = try await destination.waitForSingleDetails()
            #expect(details.level == .debug)
            #expect(details.message == "200 POST /api/v2/feeds")
            let sent = try #require(StubURLProtocol.requests.first)
            #expect(sent.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(sent.value(forHTTPHeaderField: "X-Stream-Client") == "stream-test")
            #expect(sent.httpMethod == "POST")
        }

        // MARK: -

        private var expiredTokenBody: Data {
            Data(#"{"code":40,"message":"Token expired","StatusCode":401,"duration":"","more_info":"","details":[]}"#.utf8)
        }

        private func assertRetriedTransportFailure(_ code: URLError.Code, level: LogLevel) async throws {
            let (transport, destination) = makeTransport(responses: [.failure(URLError(code))])
            defer { LogConfig.reset() }

            await #expect(throws: URLError.self) {
                try await transport.execute(request: makeRequest(path: "/api/v2/feeds"))
            }

            // Transport failures are retried, and each attempt is logged.
            let details = try await destination.waitForDetails(count: 4)
            #expect(details.allSatisfy { $0.level == level && $0.message == "FAILED GET /api/v2/feeds" })
        }

        private func makeTransport(statusCode: Int, body: Data) -> (URLSessionTransport, HTTPCapturingDestination) {
            makeTransport(responses: [.http(statusCode: statusCode, body: body)])
        }

        private func makeTransport(
            responses: [StubURLProtocol.Response],
            tokenProvider: UserTokenProvider? = nil
        ) -> (URLSessionTransport, HTTPCapturingDestination) {
            StubURLProtocol.responses = responses
            StubURLProtocol.requests = []
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [StubURLProtocol.self]
            let destination = HTTPCapturingDestination()
            LogConfig.logger = Logger(identifier: "test", destinations: [destination])
            let transport = URLSessionTransport(
                urlSession: URLSession(configuration: configuration),
                xStreamClientHeader: "stream-test",
                tokenProvider: tokenProvider
            )
            return (transport, destination)
        }

        private func makeRequest(path: String) throws -> URLRequest {
            try URLRequest(url: #require(URL(string: "https://stream.test\(path)")))
        }
    }
}

private final class TokenBox: @unchecked Sendable {
    var value = ""
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    enum Response: @unchecked Sendable {
        case http(statusCode: Int, body: Data)
        case failure(URLError)
        case nonHTTP(Data)
    }

    nonisolated(unsafe) static var responses: [Response] = [.http(statusCode: 200, body: Data())]
    nonisolated(unsafe) static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        let response = Self.responses.count > 1 ? Self.responses.removeFirst() : Self.responses[0]
        switch response {
        case let .http(statusCode, body):
            guard let url = request.url,
                  let httpResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        case let .nonHTTP(body):
            guard let url = request.url else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            let urlResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: body.count, textEncodingName: nil)
            client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}

private final class HTTPCapturingDestination: BaseLogDestination, @unchecked Sendable {
    private var logDetails: [LogDetails] = []
    private let lock = NSLock()

    init() {
        super.init(
            identifier: UUID().uuidString,
            level: .debug,
            subsystems: .httpRequests,
            showDate: false,
            dateFormatter: DateFormatter(),
            formatters: [],
            showLevel: false,
            showIdentifier: false,
            showThreadName: false,
            showFileName: false,
            showLineNumber: false,
            showFunctionName: false
        )
    }

    @available(*, unavailable)
    required init(
        identifier: String,
        level: LogLevel,
        subsystems: LogSubsystem,
        showDate: Bool,
        dateFormatter: DateFormatter,
        formatters: [LogFormatter],
        showLevel: Bool,
        showIdentifier: Bool,
        showThreadName: Bool,
        showFileName: Bool,
        showLineNumber: Bool,
        showFunctionName: Bool
    ) {
        fatalError("Unsupported initializer")
    }

    override func process(logDetails: LogDetails) {
        lock.lock()
        self.logDetails.append(logDetails)
        lock.unlock()
    }

    override func write(message: String) {}

    private var capturedDetails: [LogDetails] {
        lock.lock()
        defer { lock.unlock() }
        return logDetails
    }

    func waitForSingleDetails() async throws -> LogDetails {
        let details = try await waitForDetails(count: 1)
        return try #require(details.first)
    }

    func waitForDetails(count: Int) async throws -> [LogDetails] {
        let deadline = Date().addingTimeInterval(5)
        while capturedDetails.count < count, Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        let details = capturedDetails
        #expect(details.count == count)
        return details
    }
}
