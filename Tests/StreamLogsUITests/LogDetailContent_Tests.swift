//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamLogsUI
import Testing

struct LogDetailContent_Tests {
    @Test func httpRequestBodiesAreJSONDocuments() {
        let entry = LogEntry(
            level: .debug,
            message: "201 POST /channels",
            metadata: [
                .httpMethod: "POST",
                .httpURL: "https://example.com/channels",
                .httpStatusCode: "201",
                .httpRequestBody: #"{"limit":10}"#,
                .httpResponseBody: #"{"id":1}"#,
                .httpCURL: "$ curl -v \"https://example.com/channels\""
            ]
        )

        let subject = LogDetailContent(entry: entry)

        #expect(subject.jsonTree.roots.map { subject.jsonTree.nodes[$0].key } == [.title("Request Body"), .title("Response Body")])
        #expect(subject.json == "{\n  \"id\" : 1\n}")
        #expect(subject.curlCommand == "curl -v \"https://example.com/channels\"")
        #expect(subject.rawText == entry.rawText)
        #expect(subject.rawChunks == entry.rawText.components(separatedBy: "\n"))
        #expect(subject.rawPreviewChunkCount == nil)
        #expect(subject.copyOptions == [
            LogCopyOption(title: "Raw", text: entry.rawText),
            LogCopyOption(title: "cURL", text: "curl -v \"https://example.com/channels\""),
            LogCopyOption(title: "JSON", text: "{\n  \"id\" : 1\n}")
        ])
    }

    @Test func nonJSONBodiesAreSkipped() {
        let entry = LogEntry(
            level: .error,
            message: "500 GET /channels",
            metadata: [
                .httpMethod: "GET",
                .httpURL: "https://example.com/channels",
                .httpStatusCode: "500",
                .httpResponseBody: "<html>Internal Server Error</html>"
            ]
        )

        let subject = LogDetailContent(entry: entry)

        #expect(subject.jsonTree.isEmpty)
        #expect(subject.json == nil)
        #expect(subject.curlCommand == nil)
        #expect(subject.copyOptions.map(\.title) == ["Raw"])
    }

    @Test func webSocketPayloadIsAJSONDocument() {
        let entry = LogEntry(
            level: .debug,
            message: "Received webSocket message {\"ignored\":true}",
            metadata: [.webSocketEventType: "health.check", .webSocketReceivedPayload: #"{"type":"health.check"}"#]
        )

        let subject = LogDetailContent(entry: entry)

        #expect(subject.jsonTree.roots.map { subject.jsonTree.nodes[$0].key } == [.title("Received Payload")])
        #expect(subject.json == "{\n  \"type\" : \"health.check\"\n}")
        #expect(subject.copyOptions.map(\.title) == ["Raw", "JSON"])
    }

    @Test func otherEntriesUseTheJSONAndCurlCommandInTheirMessage() {
        let entry = LogEntry(level: .info, message: "Event received: {\"type\":\"health.check\"}\ncurl https://example.com")

        let subject = LogDetailContent(entry: entry)

        #expect(subject.jsonTree.roots.map { subject.jsonTree.nodes[$0].key } == [.title("JSON")])
        #expect(subject.json == "{\n  \"type\" : \"health.check\"\n}")
        #expect(subject.curlCommand == "curl https://example.com")
    }

    @Test func longRawTextsHaveAPreview() throws {
        let line = String(repeating: "a", count: 99)
        let entry = LogEntry(level: .debug, message: Array(repeating: line, count: 100).joined(separator: "\n"))

        let subject = LogDetailContent(entry: entry)

        let previewChunkCount = try #require(subject.rawPreviewChunkCount)
        #expect(previewChunkCount < subject.rawChunks.count)
    }
}
