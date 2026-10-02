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
}
