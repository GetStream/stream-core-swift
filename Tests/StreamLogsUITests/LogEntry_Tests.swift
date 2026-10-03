//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamLogsUI
import Testing

struct LogEntry_Tests {
    @Test func entryFromRawLoggerValuesIsNormalized() {
        let entry = LogEntry(
            date: Date(),
            level: .error,
            subsystems: ["httpRequests"],
            threadName: "[main] ",
            functionName: "function()",
            fileName: "StreamCore/Logger/Logger.swift",
            lineNumber: 42,
            message: "Hello",
            error: NSError(domain: "Boom", code: 1)
        )

        #expect(entry.threadName == "main")
        #expect(entry.functionName == "function()")
        #expect(entry.fileName == "Logger.swift")
        #expect(entry.message.hasPrefix("Hello\n"))
        #expect(entry.message.contains("Boom"))
    }

    @Test func entryFromRawLoggerValuesWithoutErrorKeepsMessage() {
        let entry = LogEntry(
            date: Date(),
            level: .info,
            subsystems: [],
            threadName: "",
            functionName: "function()",
            fileName: "File.swift",
            lineNumber: 1,
            message: "Hello",
            error: nil
        )

        #expect(entry.message == "Hello")
        #expect(entry.threadName == nil)
    }

    @Test func entryWithOnlyRequiredFieldsHasNoSourceDescription() {
        let entry = LogEntry(level: .info, message: "Hello")

        #expect(entry.subsystems.isEmpty)
        #expect(entry.metadata.isEmpty)
        #expect(entry.sourceDescription == nil)
    }

    @Test(arguments: [
        ("File.swift", UInt(42), "function()", "[File.swift:42] function()"),
        ("File.swift", nil, "function()", "[File.swift] function()"),
        ("File.swift", UInt(42), nil, "[File.swift:42]"),
        (nil, UInt(42), "function()", "function()")
    ] as [(String?, UInt?, String?, String)])
    func sourceDescriptionIncludesAvailableFields(fileName: String?, lineNumber: UInt?, functionName: String?, expected: String) {
        let entry = LogEntry(level: .info, message: "", functionName: functionName, fileName: fileName, lineNumber: lineNumber)

        #expect(entry.sourceDescription == expected)
    }

    @Test func standardLevelsAreOrderedBySeverity() {
        #expect(LogEntry.Level.standardLevels == LogEntry.Level.standardLevels.sorted())
        #expect(LogEntry.Level.warning < .error)
    }

    @Test func customLevelIsOrderedAmongStandardLevels() {
        let security = LogEntry.Level(severity: 45, name: "SECURITY")

        #expect(security > .warning)
        #expect(security < .error)
    }

    @Test func levelsWithTheSameSeverityAreEqual() {
        #expect(LogEntry.Level(severity: 40, name: "WARN") == .warning)
    }

    @Test func rawTextListsHTTPMetadataFirstAndMultilineValuesOnTheirOwnLine() {
        let entry = LogEntry(
            level: .debug,
            message: "201 POST /channels",
            metadata: [
                "Custom": "value",
                .httpResponseBody: "{\n  \"id\" : 1\n}",
                .httpStatusCode: "201",
                .httpMethod: "POST"
            ]
        )

        #expect(entry.rawText == "201 POST /channels\nMethod: POST\nStatus Code: 201\nResponse Body:\n{\n  \"id\" : 1\n}\nCustom: value")
    }

    @Test func rawTextListsWebSocketMetadataAfterHTTPMetadata() {
        let entry = LogEntry(
            level: .debug,
            message: "Received webSocket message",
            metadata: [
                "Custom": "value",
                .webSocketReceivedPayload: "{\n  \"type\" : \"message.new\"\n}",
                .webSocketEventType: "message.new"
            ]
        )

        #expect(entry.rawText == """
        Received webSocket message
        Event Type: message.new
        Received Payload:
        {
          "type" : "message.new"
        }
        Custom: value
        """)
    }

    @Test func rawTextWithoutMetadataIsTheMessage() {
        #expect(LogEntry(level: .info, message: "Hello").rawText == "Hello")
    }

    @Test func searchMatchIsTheFirstMetadataLineContainingTheSearchTextOnASingleLine() {
        let entry = LogEntry(
            level: .debug,
            message: "201 POST /channels",
            metadata: [
                .httpResponseBody: "{\n  \"text\" : \"Hello there\"\n}",
                .httpRequestBody: "{\n  \"limit\" : 10\n}",
                .httpMethod: "POST"
            ]
        )

        #expect(entry.searchMatch("hello", displayedTexts: ["/channels"]) == "Response Body: { \"text\" : \"Hello there\" }")
        #expect(entry.searchMatch("LIMIT", displayedTexts: ["/channels"]) == "Request Body: { \"limit\" : 10 }")
    }

    @Test func searchMatchIsNilWhenADisplayedTextContainsTheSearchText() {
        let entry = LogEntry(level: .debug, message: "201 POST /channels", metadata: [.httpResponseBody: "{\"channels\":[]}"])

        #expect(entry.searchMatch("channels", displayedTexts: ["POST", "/channels"]) == nil)
    }

    @Test func searchMatchIsNilWithoutSearchTextOrMatch() {
        let entry = LogEntry(level: .debug, message: "Hello", metadata: ["Custom": "value"])

        #expect(entry.searchMatch("", displayedTexts: []) == nil)
        #expect(entry.searchMatch("missing", displayedTexts: []) == nil)
    }

    @Test func searchMatchFallsBackToTheSourceLocation() {
        let entry = LogEntry(level: .debug, message: "Hello", functionName: "connect()", fileName: "WebSocketClient.swift", lineNumber: 7)

        #expect(entry.searchMatch("connect", displayedTexts: ["Hello"]) == "[WebSocketClient.swift:7] connect()")
    }

    @Test func httpRequestIsReadFromMetadata() throws {
        let entry = LogEntry(
            level: .debug,
            message: "201 POST /channels",
            metadata: [
                .httpMethod: "post",
                .httpURL: "https://chat.stream-io-api.com/channels?api_key=key",
                .httpStatusCode: "201",
                .httpRequestBody: "{}",
                .httpResponseBody: "{\"id\":1}",
                .httpCURL: "$ curl -v \"https://chat.stream-io-api.com/channels\""
            ]
        )

        let request = try #require(entry.httpRequest)

        #expect(request.method == "POST")
        #expect(request.path == "/channels")
        #expect(request.host == "chat.stream-io-api.com")
        #expect(request.status == .success(201))
        #expect(request.requestBody == "{}")
        #expect(request.responseBody == "{\"id\":1}")
        #expect(request.curlCommand == "$ curl -v \"https://chat.stream-io-api.com/channels\"")
    }

    @Test func httpRequestWithErrorAndWithoutStatusFailed() throws {
        let entry = LogEntry(
            level: .error,
            message: "FAILED GET /channels",
            metadata: [.httpMethod: "GET", .httpURL: "https://example.com/channels", .httpError: "Offline"]
        )

        let request = try #require(entry.httpRequest)

        #expect(request.status == .failed)
        #expect(request.error == "Offline")
    }

    @Test func httpMetadataIsCreatedFromARequestAndResponse() throws {
        let url = try #require(URL(string: "https://example.com/channels"))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(#"{"limit":10}"#.utf8)
        let response = try #require(HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil))

        let entry = LogEntry(
            level: .debug,
            message: "201 POST /channels",
            metadata: .http(request: request, response: response, responseBody: Data([0xff, 0xd8]))
        )

        let httpRequest = try #require(entry.httpRequest)
        #expect(httpRequest.method == "POST")
        #expect(httpRequest.url == "https://example.com/channels")
        #expect(httpRequest.status == .success(201))
        #expect(httpRequest.requestBody == "{\n  \"limit\" : 10\n}")
        #expect(httpRequest.responseBody == nil)
        #expect(httpRequest.curlCommand == """
        $ curl -v \\
        \t-X POST \\
        \t-H "Content-Type: application/json" \\
        \t-d "{\\"limit\\":10}" \\
        \t"https://example.com/channels"
        """)
    }

    @Test func httpMetadataOfAFailedRequestHasTheError() throws {
        let request = URLRequest(url: try #require(URL(string: "https://example.com/channels")))

        let entry = LogEntry(level: .error, message: "FAILED GET /channels", metadata: .http(request: request, error: URLError(.timedOut)))

        let httpRequest = try #require(entry.httpRequest)
        #expect(httpRequest.method == "GET")
        #expect(httpRequest.status == .failed)
        #expect(httpRequest.error != nil)
    }

    @Test func httpRequestRequiresMethodAndURL() {
        #expect(LogEntry(level: .info, message: "", metadata: [.httpMethod: "GET"]).httpRequest == nil)
        #expect(LogEntry(level: .info, message: "", metadata: [.httpURL: "https://example.com"]).httpRequest == nil)
        #expect(LogEntry(level: .info, message: "", metadata: [:]).httpRequest == nil)
    }

    @Test func receivedWebSocketMessageIsReadFromMetadata() throws {
        let entry = LogEntry(
            level: .debug,
            message: "Received webSocket message",
            metadata: [.webSocketEventType: "message.new", .webSocketReceivedPayload: "{}"]
        )

        let message = try #require(entry.webSocketMessage)

        #expect(message == LogWebSocketMessage(
            direction: .received,
            eventType: "message.new",
            payloadKey: .webSocketReceivedPayload,
            payload: "{}"
        ))
    }

    @Test func sentWebSocketMessageMayHaveNoEventType() throws {
        let entry = LogEntry(level: .debug, message: "Sent webSocket message", metadata: [.webSocketSentPayload: "{}"])

        let message = try #require(entry.webSocketMessage)

        #expect(message == LogWebSocketMessage(direction: .sent, eventType: nil, payloadKey: .webSocketSentPayload, payload: "{}"))
    }

    @Test func webSocketMessageRequiresPayload() {
        #expect(LogEntry(level: .info, message: "", metadata: [.webSocketEventType: "message.new"]).webSocketMessage == nil)
        #expect(LogEntry(level: .info, message: "", metadata: [:]).webSocketMessage == nil)
    }

    @Test(arguments: [
        (100, LogHTTPRequest.Status.informational(100), "Continue"),
        (200, .success(200), "OK"),
        (204, .success(204), "No Content"),
        (299, .success(299), "Success"),
        (304, .redirection(304), "Not Modified"),
        (404, .clientError(404), "Not Found"),
        (429, .clientError(429), "Too Many Requests"),
        (500, .serverError(500), "Internal Server Error"),
        (599, .serverError(599), "Server Error")
    ])
    func httpStatusIsGroupedByClass(code: Int, status: LogHTTPRequest.Status, reasonPhrase: String) {
        let subject = LogHTTPRequest.Status(statusCode: code)

        #expect(subject == status)
        #expect(subject.code == code)
        #expect(subject.reasonPhrase == reasonPhrase)
    }
}
