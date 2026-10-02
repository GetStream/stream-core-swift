//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamLogsUI
import XCTest

final class LogMessageParser_Tests: XCTestCase {
    func test_chunks_splitsLinesAndKeepsEmptyLines() {
        XCTAssertEqual(LogMessageParser.chunks(of: "first\n\nthird", maxLength: 10), ["first", "", "third"])
    }

    func test_chunks_cutsLongLines() {
        let message = "short\n" + String(repeating: "a", count: 25)

        XCTAssertEqual(
            LogMessageParser.chunks(of: message, maxLength: 10),
            ["short", String(repeating: "a", count: 10), String(repeating: "a", count: 10), String(repeating: "a", count: 5)]
        )
    }

    func test_preview_shortMessage_returnsNil() {
        XCTAssertNil(LogMessageParser.preview(of: "Short message", maxLength: 20))
        XCTAssertNil(LogMessageParser.preview(of: String(repeating: "a", count: 20), maxLength: 20))
    }

    func test_preview_longMessageWithoutLineBreaks_cutsAtMaxLength() {
        let message = String(repeating: "a", count: 30)

        XCTAssertEqual(LogMessageParser.preview(of: message, maxLength: 20), String(repeating: "a", count: 20))
    }

    func test_preview_lineBreakNearLimit_cutsAtLineBreak() {
        let message = String(repeating: "a", count: 15) + "\n" + String(repeating: "b", count: 15)

        XCTAssertEqual(LogMessageParser.preview(of: message, maxLength: 20), String(repeating: "a", count: 15))
    }

    func test_preview_lineBreakFarFromLimit_cutsAtMaxLength() {
        let message = "aaa\n" + String(repeating: "b", count: 30)

        XCTAssertEqual(LogMessageParser.preview(of: message, maxLength: 20), "aaa\n" + String(repeating: "b", count: 16))
    }

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
