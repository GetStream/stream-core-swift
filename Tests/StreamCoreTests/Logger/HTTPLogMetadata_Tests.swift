//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

struct HTTPLogMetadata_Tests {
    private let url = URL(string: "https://chat.stream-io-api.com/channels/query?api_key=key")!

    @Test func containsRequestResponseAndPrettyPrintedJSONBodies() throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"limit":10}"#.utf8)
        let response = try #require(HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil))

        let metadata: [LogMetadataKey: String] = .http(
            request: request,
            response: response,
            responseBody: Data(#"{"url":"https://a.b/c"}"#.utf8),
            session: .shared
        )

        #expect(metadata == [
            .httpMethod: "POST",
            .httpURL: url.absoluteString,
            .httpStatusCode: "201",
            .httpRequestBody: "{\n  \"limit\" : 10\n}",
            .httpResponseBody: "{\n  \"url\" : \"https://a.b/c\"\n}",
            .httpCURL: request.cURLRepresentation(in: .shared)
        ])
    }

    @Test func failedRequestHasErrorAndNoStatus() {
        let metadata: [LogMetadataKey: String] = .http(request: URLRequest(url: url), error: RequestError())

        #expect(metadata[.httpMethod] == "GET")
        #expect(metadata[.httpError] == "RequestError()")
        #expect(metadata[.httpStatusCode] == nil)
        #expect(metadata[.httpResponseBody] == nil)
    }

    @Test func textBodiesAreKeptAndBinaryBodiesAreSkipped() {
        var request = URLRequest(url: url)
        request.httpBody = Data([0xff, 0xd8, 0xff, 0xe0])

        let metadata: [LogMetadataKey: String] = .http(request: request, responseBody: Data("<html>Error</html>".utf8))

        #expect(metadata[.httpRequestBody] == nil)
        #expect(metadata[.httpResponseBody] == "<html>Error</html>")
    }

    @Test func curlCommandIncludesTheSessionHeaders() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["X-Stream-Client": "stream-chat-swift"]
        let session = URLSession(configuration: configuration)

        let metadata: [LogMetadataKey: String] = .http(request: URLRequest(url: url), session: session)

        #expect(metadata[.httpCURL]?.contains(#"-H "X-Stream-Client: stream-chat-swift""#) == true)
    }
}

private struct RequestError: Error {}
