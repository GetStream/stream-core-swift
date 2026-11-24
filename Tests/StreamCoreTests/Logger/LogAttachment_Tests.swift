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
        request.setValue("jwt", forHTTPHeaderField: "Stream-Auth-Type")

        let attachment = HTTPLogAttachment(request: request, session: URLSession(configuration: configuration))

        #expect(attachment.logDescription == """
        cURL:
        $ curl -v \\
        \t-X GET \\
        \t-H "Stream-Auth-Type: jwt" \\
        \t-H "X-Stream-Client: stream-chat-swift" \\
        \t"\(url.absoluteString)"
        """)
    }

    @Test func httpAttachmentRedactsCredentialHeaders() {
        var request = URLRequest(url: url)
        request.setValue("secret-token", forHTTPHeaderField: "Authorization")
        request.setValue("secret-proxy", forHTTPHeaderField: "Proxy-Authorization")
        request.setValue("session=secret-cookie", forHTTPHeaderField: "Cookie")
        request.setValue("jwt", forHTTPHeaderField: "Stream-Auth-Type")

        let attachment = HTTPLogAttachment(request: request)

        #expect(attachment.logDescription == """
        cURL:
        $ curl -v \\
        \t-X GET \\
        \t-H "Authorization: <redacted>" \\
        \t-H "Cookie: <redacted>" \\
        \t-H "Proxy-Authorization: <redacted>" \\
        \t-H "Stream-Auth-Type: jwt" \\
        \t"\(url.absoluteString)"
        """)
        #expect(attachment.request.value(forHTTPHeaderField: "Authorization") == "<redacted>")
        #expect(attachment.request.value(forHTTPHeaderField: "Proxy-Authorization") == "<redacted>")
        #expect(attachment.request.value(forHTTPHeaderField: "Cookie") == "<redacted>")
        #expect(attachment.request.value(forHTTPHeaderField: "Stream-Auth-Type") == "jwt")
    }

    @Test func httpDescriptionRedactsTheSessionAuthorizationHeader() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["authorization": "secret-token"]

        let attachment = HTTPLogAttachment(request: URLRequest(url: url), session: URLSession(configuration: configuration))

        #expect(!attachment.logDescription.contains("secret-token"))
        #expect(attachment.logDescription.contains(#"-H "authorization: <redacted>""#))
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

    @Test func webSocketAttachmentRedactsTheTokenOfTheAuthMessage() throws {
        let payload = Data(#"{"products":["feeds"],"token":"secret-token","user_details":{"id":"luke"}}"#.utf8)

        let attachment = WebSocketLogAttachment(direction: .sent, payload: payload)

        #expect(!attachment.logDescription.contains("secret-token"))
        let object = try #require(JSONSerialization.jsonObject(with: attachment.payload) as? [String: Any])
        #expect(object["token"] as? String == "<redacted>")
        #expect((object["user_details"] as? [String: Any])?["id"] as? String == "luke")
        #expect(object["products"] as? [String] == ["feeds"])
    }

    @Test func webSocketAttachmentKeepsPayloadsWithoutATopLevelToken() {
        let event = Data(#"{"type":"feeds.activity.added","activity":{"token":"not-a-credential"}}"#.utf8)
        let text = Data("token".utf8)

        #expect(WebSocketLogAttachment(direction: .received, payload: event).payload == event)
        #expect(WebSocketLogAttachment(direction: .sent, payload: text).payload == text)
    }

    @Test func webSocketDescriptionOfABinaryPayloadIsItsSize() {
        let attachment = WebSocketLogAttachment(direction: .received, payload: Data([0xff, 0xfe, 0x00]))

        #expect(attachment.logDescription == "<3 bytes>")
    }
}

private struct RequestError: Error {}
