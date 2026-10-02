//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamLogsUI
import Testing

struct LogSession_Tests {
    private let date = Date(timeIntervalSince1970: 1_790_000_000.25)

    @Test func encodedSessionIsDecodedWithTheSameValues() throws {
        let entry = LogEntry(
            date: date,
            level: LogEntry.Level(severity: 45, name: "SECURITY"),
            subsystems: ["httpRequests", "authentication"],
            message: "Request",
            threadName: "main",
            functionName: "send()",
            fileName: "APIClient.swift",
            lineNumber: 42,
            metadata: [.httpMethod: "POST", .httpStatusCode: "200", "Custom": "Value"]
        )
        let session = makeSession(entries: [entry, LogEntry(date: date, level: .debug, message: "Plain")])

        let decoded = try LogSession(data: session.encoded())

        #expect(decoded.formatVersion == LogSession.currentFormatVersion)
        #expect(decoded.exportDate == date)
        #expect(decoded.appName == "DemoApp")
        #expect(decoded.appIdentifier == "io.getstream.DemoApp")
        #expect(decoded.appVersion == "5.0")
        #expect(decoded.appBuild == "123")
        #expect(decoded.systemVersion == "iOS 26.0.1")
        #expect(decoded.deviceModel == "iPhone17,1")
        #expect(decoded.entries.count == 2)

        let decodedEntry = try #require(decoded.entries.first)
        #expect(decodedEntry.id == entry.id)
        #expect(decodedEntry.date == entry.date)
        #expect(decodedEntry.level.severity == 45)
        #expect(decodedEntry.level.name == "SECURITY")
        #expect(decodedEntry.subsystems == entry.subsystems)
        #expect(decodedEntry.message == entry.message)
        #expect(decodedEntry.threadName == entry.threadName)
        #expect(decodedEntry.functionName == entry.functionName)
        #expect(decodedEntry.fileName == entry.fileName)
        #expect(decodedEntry.lineNumber == entry.lineNumber)
        #expect(decodedEntry.metadata == entry.metadata)
        #expect(decoded.entries.last?.message == "Plain")
    }

    @Test func datesAreEncodedAsISO8601WithMilliseconds() throws {
        let json = try String(decoding: makeSession(entries: []).encoded(), as: UTF8.self)

        #expect(json.contains("\"exportDate\" : \"2026-09-21T14:13:20.250Z\""))
    }

    @Test func metadataIsEncodedAsAnObject() throws {
        let entry = LogEntry(date: date, level: .info, message: "Request", metadata: [.httpURL: "https://example.com/a"])

        let json = try String(decoding: makeSession(entries: [entry]).encoded(), as: UTF8.self)

        #expect(json.contains("\"URL\" : \"https://example.com/a\""))
    }

    @Test func minimalEntriesAreDecoded() throws {
        let json = """
        {
          "formatVersion": 1,
          "exportDate": "2026-09-21T14:13:20Z",
          "entries": [
            { "date": "2026-09-21T14:13:20Z", "level": { "severity": 20, "name": "INFO" }, "message": "Hello" }
          ]
        }
        """

        let session = try LogSession(data: Data(json.utf8))

        #expect(session.exportDate == Date(timeIntervalSince1970: 1_790_000_000))
        #expect(session.appName == nil)
        let entry = try #require(session.entries.first)
        #expect(entry.level == .info)
        #expect(entry.message == "Hello")
        #expect(entry.subsystems.isEmpty)
        #expect(entry.metadata.isEmpty)
    }

    @Test func invalidDataIsNotDecoded() {
        #expect(throws: DecodingError.self) {
            try LogSession(data: Data(#"{ "formatVersion": 1, "exportDate": "yesterday", "entries": [] }"#.utf8))
        }
    }

    @Test func fileNameIncludesTheAppNameAndExportDate() {
        let fileName = makeSession(entries: []).fileName

        #expect(fileName.hasPrefix("DemoApp Logs "))
        #expect(fileName.hasSuffix(".json"))
    }

    @Test func sourceDescriptionIncludesTheAppAndDevice() {
        #expect(makeSession(entries: []).sourceDescription == "DemoApp 5.0 (123) · iOS 26.0.1 · iPhone17,1")
    }

    @Test func recorderFromSessionHasItsEntriesAndDoesNotRecord() {
        let session = makeSession(entries: [LogEntry(date: date, level: .info, message: "Hello")])

        let recorder = InMemoryLogRecorder(session: session)
        recorder.record(LogEntry(level: .info, message: "New"))

        #expect(recorder.isRecording == false)
        #expect(recorder.entries.map(\.message) == ["Hello"])
    }

    @Test func exportedFileContainsTheSession() throws {
        guard #available(iOS 16.0, *) else { return }
        let file = LogSessionFile { [LogEntry(level: .info, message: "Hello")] }

        let url = try file.write()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        #expect(url.pathExtension == "json")
        #expect(try LogSession.read(from: url).entries.map(\.message) == ["Hello"])
    }

    private func makeSession(entries: [LogEntry]) -> LogSession {
        LogSession(
            entries: entries,
            exportDate: date,
            appName: "DemoApp",
            appIdentifier: "io.getstream.DemoApp",
            appVersion: "5.0",
            appBuild: "123",
            systemVersion: "iOS 26.0.1",
            deviceModel: "iPhone17,1"
        )
    }
}
