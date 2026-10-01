//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
@testable import StreamLogsUI
import Testing

struct InMemoryLogStore_Tests {
    private let subject = InMemoryLogStore(capacity: 3)

    @Test func appendRecordsEntry() throws {
        let entry = makeEntry(message: "Hello")

        subject.append(entry)

        let entries = subject.entries
        #expect(entries.count == 1)
        #expect(try #require(entries.first).id == entry.id)
    }

    @Test func appendIgnoresEntriesWhenNotRecording() {
        subject.isRecording = false

        subject.append(makeEntry(message: "Hello"))

        #expect(subject.entries.isEmpty)
    }

    @Test func appendDropsOldestEntriesWhenCapacityIsExceeded() {
        (1...5).forEach { subject.append(makeEntry(message: "\($0)")) }

        #expect(subject.entries.map(\.message) == ["3", "4", "5"])
    }

    @Test func removeEntriesUpdatesEntries() {
        let first = makeEntry(message: "1")
        subject.append(first)
        subject.append(makeEntry(message: "2"))

        subject.removeEntry(id: first.id)
        #expect(subject.entries.map(\.message) == ["2"])

        subject.removeAll()
        #expect(subject.entries.isEmpty)
    }

    @Test func levelRawValuesMatchStreamCoreLogLevel() {
        let coreLevels: [LogLevel] = [.debug, .info, .warning, .error]

        #expect(LogEntry.Level.allCases.map(\.rawValue) == coreLevels.map(\.rawValue))
    }

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

    // MARK: - Private Helpers

    private func makeEntry(message: String) -> LogEntry {
        LogEntry(
            date: Date(),
            level: .debug,
            subsystems: ["Other"],
            message: message,
            threadName: "main",
            functionName: "function()",
            fileName: "File.swift",
            lineNumber: 1
        )
    }
}
