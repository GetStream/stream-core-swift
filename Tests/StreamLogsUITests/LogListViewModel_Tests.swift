//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamLogsUI
import XCTest

@MainActor
final class LogListViewModel_Tests: XCTestCase {
    private var store: InMemoryLogStore!
    private var subject: LogListViewModel!

    override func setUp() async throws {
        try await super.setUp()
        store = InMemoryLogStore()
        store.append(makeEntry(level: .debug, subsystems: ["HTTP"], message: "GET channels"))
        store.append(makeEntry(level: .error, subsystems: ["WebSocket"], message: "Socket disconnected"))
        store.append(makeEntry(level: .error, subsystems: ["Database", "Offline"], message: "Failed to save"))
        subject = LogListViewModel(store: store)
    }

    override func tearDown() async throws {
        subject = nil
        store = nil
        try await super.tearDown()
    }

    func test_filteredEntries_withoutFilters_returnsNewestFirst() {
        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Failed to save", "Socket disconnected", "GET channels"])
        XCTAssertFalse(subject.isFiltering)
    }

    func test_filteredEntries_filtersByLevel() {
        subject.selectedLevel = .error

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Failed to save", "Socket disconnected"])
        XCTAssertTrue(subject.isFiltering)
    }

    func test_filteredEntries_filtersBySubsystems() {
        subject.selectedSubsystems = ["HTTP", "Offline"]

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Failed to save", "GET channels"])
    }

    func test_filteredEntries_filtersBySearchText() {
        subject.searchText = "socket"

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Socket disconnected"])
    }

    func test_filteredEntries_searchMatchesSubsystem() {
        subject.searchText = "http"

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["GET channels"])
    }

    func test_availableSubsystems_includesRecordedAndSelectedSubsystemsSorted() {
        subject.selectedSubsystems = ["Auth"]

        XCTAssertEqual(subject.availableSubsystems, ["Auth", "Database", "HTTP", "Offline", "WebSocket"])
    }

    func test_isRecording_updatesStore() {
        subject.isRecording = false

        XCTAssertFalse(store.isRecording)
    }

    // MARK: - Private Helpers

    private func makeEntry(level: LogEntry.Level, subsystems: [String], message: String) -> LogEntry {
        LogEntry(
            date: Date(),
            level: level,
            subsystems: subsystems,
            threadName: "main",
            functionName: "function()",
            fileName: "File.swift",
            lineNumber: 1,
            message: message
        )
    }
}
