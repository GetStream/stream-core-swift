//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

struct LogAttachment_Tests {
    private let url = URL(string: "https://chat.stream-io-api.com/channels/query?api_key=key")!

    @Test func httpDescriptionHasTheCURLAndPrettyPrintedJSONBodies() throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(#"{"limit":10}"#.utf8)
        let response = try #require(HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil))

        let attachment = HTTPLogAttachment(
            request: request,
            response: response,
            responseBody: Data(#"{"url":"https://a.b/c"}"#.utf8)
        )

        #expect(attachment.logDescription == """
        cURL:
        $ curl -v \\
        \t-X POST \\
        \t-H "Content-Type: application/json" \\
        \t-d "{\\"limit\\":10}" \\
        \t"\(url.absoluteString)"
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

        #expect(attachment.logDescription == """
        cURL:
        $ curl -v \\
        \t-X GET \\
        \t"\(url.absoluteString)"
        Error: RequestError()
        """)
    }

    @Test func httpDescriptionHasTheSessionAdditionalHeadersInTheCURL() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["X-Stream-Client": "stream-chat-swift"]
        var request = URLRequest(url: url)
        request.setValue("token", forHTTPHeaderField: "Authorization")

        let attachment = HTTPLogAttachment(request: request, session: URLSession(configuration: configuration))

        #expect(attachment.logDescription == """
        cURL:
        $ curl -v \\
        \t-X GET \\
        \t-H "Authorization: token" \\
        \t-H "X-Stream-Client: stream-chat-swift" \\
        \t"\(url.absoluteString)"
        """)
    }

    @Test func httpDescriptionKeepsTextBodiesAndSkipsBinaryBodies() {
        var request = URLRequest(url: url)
        request.httpBody = Data([0xff, 0xd8, 0xff, 0xe0])

        let attachment = HTTPLogAttachment(request: request, responseBody: Data("<html>Error</html>".utf8))

        #expect(attachment.logDescription.hasSuffix("\t\"\(url.absoluteString)\"\nResponse Body:\n<html>Error</html>"))
        #expect(!attachment.logDescription.contains("Request Body:"))
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
