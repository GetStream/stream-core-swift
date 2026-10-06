//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

struct LogAttachment_Tests {
    private let url = URL(string: "https://chat.stream-io-api.com/channels/query?api_key=key")!

    @Test func httpDescriptionHasTheURLAndPrettyPrintedJSONBodies() throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"limit":10}"#.utf8)
        let response = try #require(HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil))

        let attachment = HTTPLogAttachment(
            request: request,
            response: response,
            responseBody: Data(#"{"url":"https://a.b/c"}"#.utf8)
        )

        #expect(attachment.logDescription == """
        URL: \(url.absoluteString)
        Request Body:
        {
          "limit" : 10
        }
        Response Body:
        {
          "url" : "https://a.b/c"
        }
        """)
    }

    @Test func httpDescriptionOfAFailedRequestHasTheError() {
        let attachment = HTTPLogAttachment(request: URLRequest(url: url), error: RequestError())

        #expect(attachment.logDescription == "URL: \(url.absoluteString)\nError: RequestError()")
    }

    @Test func httpDescriptionKeepsTextBodiesAndSkipsBinaryBodies() {
        var request = URLRequest(url: url)
        request.httpBody = Data([0xff, 0xd8, 0xff, 0xe0])

        let attachment = HTTPLogAttachment(request: request, responseBody: Data("<html>Error</html>".utf8))

        #expect(attachment.logDescription == "URL: \(url.absoluteString)\nResponse Body:\n<html>Error</html>")
    }

    @Test func webSocketDescriptionIsThePrettyPrintedJSONPayload() {
        let attachment = WebSocketLogAttachment(direction: .received, payload: Data(#"{"type":"message.new"}"#.utf8))

        #expect(attachment.logDescription == "{\n  \"type\" : \"message.new\"\n}")
    }

    @Test func webSocketDescriptionOfABinaryPayloadIsItsSize() {
        let attachment = WebSocketLogAttachment(direction: .received, payload: Data([0xff, 0xfe, 0x00]))

        #expect(attachment.logDescription == "<3 bytes>")
    }
}

private struct RequestError: Error {}
