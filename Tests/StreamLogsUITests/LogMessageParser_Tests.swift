//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamLogsUI
import XCTest

final class LogMessageParser_Tests: XCTestCase {
    func test_curlCommand_returnsCommandAtEndOfMessage() {
        let message = """
        200 api/v2/channels
        {"ok":true}

        curl 'https://example.com/channels' \\
          -X POST \\
          --data-raw '{"limit":1}'
        """

        XCTAssertEqual(
            LogMessageParser.curlCommand(in: message),
            """
            curl 'https://example.com/channels' \\
              -X POST \\
              --data-raw '{"limit":1}'
            """
        )
    }

    func test_curlCommand_dropsShellPromptPrefix() {
        let message = "$ curl -v \\\n\t-X GET \\\n\t\"https://example.com\""

        XCTAssertEqual(LogMessageParser.curlCommand(in: message), "curl -v \\\n\t-X GET \\\n\t\"https://example.com\"")
    }

    func test_curlCommand_ignoresCurlInsideText() {
        XCTAssertNil(LogMessageParser.curlCommand(in: "Failed to create curl command"))
    }

    func test_json_returnsPrettyPrintedObject() {
        let message = "Event received:\n{\"type\":\"health.check\",\"me\":{\"id\":\"luke\"}}"

        XCTAssertEqual(
            LogMessageParser.json(in: message),
            """
            {
              "me" : {
                "id" : "luke"
              },
              "type" : "health.check"
            }
            """
        )
    }

    func test_json_skipsInvalidBraceGroupsAndHandlesBracesInsideStrings() {
        let message = "<NSHTTPURLResponse> { URL: https://example.com } {\"text\":\"a } b\"}"

        XCTAssertEqual(LogMessageParser.json(in: message), "{\n  \"text\" : \"a } b\"\n}")
    }

    func test_json_returnsNilWithoutJSON() {
        XCTAssertNil(LogMessageParser.json(in: "Connection state changed to connected"))
    }
}
