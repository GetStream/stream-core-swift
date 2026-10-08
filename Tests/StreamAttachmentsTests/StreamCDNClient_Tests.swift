//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamAttachments
@testable import StreamCore
import Testing

@Suite(.serialized)
struct StreamCDNClient_Tests {
    @Test func successfulUploadIsLoggedOnceAtDebugLevel() async throws {
        let body = Data(#"{"file":"https://cdn.stream.test/file.png"}"#.utf8)
        defer { LogConfig.reset() }
        let destination = try await upload(response: .http(statusCode: 201, body: body))

        let details = try await destination.waitForSingleDetails()
        #expect(details.level == .debug)
        #expect(details.message == "201 POST /uploads/file")
        #expect(details.subsystem == .httpRequests)
        let attachment = try #require(details.attachment as? HTTPLogAttachment)
        #expect(attachment.request.httpBody == nil)
        #expect(attachment.responseBody == body)
        #expect(attachment.error == nil)
    }

    @Test func failedUploadIsLoggedOnceAtErrorLevel() async throws {
        let body = Data(#"{"code":4,"message":"Invalid input","StatusCode":400,"duration":"","more_info":"","details":[]}"#.utf8)
        defer { LogConfig.reset() }
        let destination = try await upload(response: .http(statusCode: 400, body: body))

        let details = try await destination.waitForSingleDetails()
        #expect(details.level == .error)
        #expect(details.message == "400 POST /uploads/file")
        let attachment = try #require(details.attachment as? HTTPLogAttachment)
        #expect(attachment.error is ClientError)
        #expect(attachment.responseBody == body)
    }

    @Test func expiredTokenIsLoggedAtInfoLevel() async throws {
        let body = Data(#"{"code":40,"message":"Token expired","StatusCode":401,"duration":"","more_info":"","details":[]}"#.utf8)
        defer { LogConfig.reset() }
        let destination = try await upload(response: .http(statusCode: 401, body: body))

        let details = try await destination.waitForSingleDetails()
        #expect(details.level == .info)
        #expect(details.message == "401 POST /uploads/file")
    }

    @Test func lostConnectionIsLoggedAtInfoLevel() async throws {
        defer { LogConfig.reset() }
        let destination = try await upload(response: .failure(URLError(.networkConnectionLost)))

        let details = try await destination.waitForSingleDetails()
        #expect(details.level == .info)
        #expect(details.message == "FAILED POST /uploads/file")
        let attachment = try #require(details.attachment as? HTTPLogAttachment)
        #expect(attachment.response == nil)
    }

    // MARK: -

    private func upload(response: StubURLProtocol.Response) async throws -> HTTPCapturingDestination {
        StubURLProtocol.response = response
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let client = StreamCDNClient(
            encoder: StubRequestEncoder(baseURL: try #require(URL(string: "https://stream.test")), apiKey: APIKey("key")),
            decoder: DefaultRequestDecoder(),
            sessionConfiguration: configuration
        )
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).png")
        try Data("image".utf8).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let attachment = AnyStreamAttachment(
            id: AttachmentId(fid: "user:1", activityId: "activity", index: 0),
            type: .image,
            payload: Data(),
            downloadingState: nil,
            uploadingState: AttachmentUploadingState(
                localFileURL: fileURL,
                state: .pendingUpload,
                file: AttachmentFile(type: .png, size: 5, mimeType: "image/png")
            )
        )
        let destination = HTTPCapturingDestination()
        LogConfig.logger = Logger(identifier: "test", destinations: [destination])

        await withCheckedContinuation { continuation in
            client.uploadAttachment(attachment, progress: nil) { (_: Result<UploadedFile, Error>) in
                continuation.resume()
            }
        }
        return destination
    }
}

private final class StubRequestEncoder: RequestEncoder, @unchecked Sendable {
    let baseURL: URL
    var connectionDetailsProviderDelegate: ConnectionDetailsProviderDelegate?

    init(baseURL: URL, apiKey: APIKey) {
        self.baseURL = baseURL
    }

    func encodeRequest<ResponsePayload: Decodable>(
        for endpoint: Endpoint<ResponsePayload>,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var request = URLRequest(url: baseURL.appendingPathComponent("uploads/file"))
        request.httpMethod = "POST"
        completion(.success(request))
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    enum Response {
        case http(statusCode: Int, body: Data)
        case failure(URLError)
    }

    nonisolated(unsafe) static var response: Response = .http(statusCode: 200, body: Data())

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        switch Self.response {
        case let .http(statusCode, body):
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
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
