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
        #expect(subject.rawPreview == nil)
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
    }

    @Test func otherEntriesUseTheJSONAndCurlCommandInTheirMessage() {
        let entry = LogEntry(level: .info, message: "Event received: {\"type\":\"health.check\"}\ncurl https://example.com")

        let subject = LogDetailContent(entry: entry)

        #expect(subject.jsonTree.roots.map { subject.jsonTree.nodes[$0].key } == [.title("JSON")])
        #expect(subject.json == "{\n  \"type\" : \"health.check\"\n}")
        #expect(subject.curlCommand == "curl https://example.com")
    }
}
