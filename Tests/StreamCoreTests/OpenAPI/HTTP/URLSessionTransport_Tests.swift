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
            let body = Data(#"{"code":40,"message":"Token expired","StatusCode":401,"duration":"","more_info":"","details":[]}"#.utf8)
            let (transport, destination) = makeTransport(statusCode: 401, body: body)
            defer { LogConfig.reset() }

            await #expect(throws: APIError.self) {
                try await transport.execute(request: makeRequest(path: "/api/v2/feeds"))
            }

            let details = try await destination.waitForSingleDetails()
            #expect(details.level == .info)
            #expect(details.message == "401 GET /api/v2/feeds")
        }

        // MARK: -

        private func makeTransport(statusCode: Int, body: Data) -> (URLSessionTransport, HTTPCapturingDestination) {
            StubURLProtocol.response = (statusCode, body)
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [StubURLProtocol.self]
            let destination = HTTPCapturingDestination()
            LogConfig.logger = Logger(identifier: "test", destinations: [destination])
            let transport = URLSessionTransport(
                urlSession: URLSession(configuration: configuration),
                xStreamClientHeader: "stream-test"
            )
            return (transport, destination)
        }

        private func makeRequest(path: String) throws -> URLRequest {
            try URLRequest(url: #require(URL(string: "https://stream.test\(path)")))
        }
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var response: (statusCode: Int, body: Data) = (200, Data())

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: Self.response.statusCode, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.response.body)
        client?.urlProtocolDidFinishLoading(self)
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
        let deadline = Date().addingTimeInterval(5)
        while capturedDetails.isEmpty, Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        let details = capturedDetails
        #expect(details.count == 1)
        return try #require(details.first)
    }
}
