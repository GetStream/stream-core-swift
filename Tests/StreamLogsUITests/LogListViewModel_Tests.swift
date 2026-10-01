//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
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

    func test_filteredEntries_filtersByMinimumLevel() {
        subject.minimumLevel = .error

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Failed to save", "Socket disconnected"])
        XCTAssertTrue(subject.isFiltering)
    }

    func test_filteredEntries_minimumLevelIncludesMoreSevereLevels() {
        subject.minimumLevel = .warning

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Failed to save", "Socket disconnected"])
    }

    func test_availableLevels_includesRecordedLevelsSortedBySeverity() {
        let security = LogEntry.Level(severity: 45, name: "SECURITY")
        store.append(LogEntry(level: security, message: "Token refreshed"))
        subject = LogListViewModel(store: store)

        XCTAssertEqual(subject.availableLevels, [.debug, security, .error])
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

    func test_filteredEntries_searchMatchesMetadata() {
        store.append(LogEntry(level: .info, message: "Tapped", metadata: ["category": "Navigation"]))
        subject = LogListViewModel(store: store)

        subject.searchText = "navigation"

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Tapped"])
    }

    func test_availableSubsystems_includesRecordedAndSelectedSubsystemsSorted() {
        subject.selectedSubsystems = ["Auth"]

        XCTAssertEqual(subject.availableSubsystems, ["Auth", "Database", "HTTP", "Offline", "WebSocket"])
    }

    func test_isRecording_updatesStore() {
        subject.isRecording = false

        XCTAssertFalse(store.isRecording)
    }

    func test_customStore_providesEntriesAndReceivesRemovals() {
        let customStore = SpyLogStore(entries: [makeEntry(level: .info, subsystems: ["HTTP"], message: "Custom")])
        let subject = LogListViewModel(store: customStore)

        subject.removeEntry(customStore.entries[0])
        subject.removeAll()

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Custom"])
        XCTAssertEqual(customStore.removedEntryIDs, [customStore.entries[0].id])
        XCTAssertEqual(customStore.removeAllCallCount, 1)
    }

    // MARK: - Private Helpers

    private func makeEntry(level: LogEntry.Level, subsystems: [String], message: String) -> LogEntry {
        LogEntry(
            date: Date(),
            level: level,
            subsystems: subsystems,
            message: message,
            threadName: "main",
            functionName: "function()",
            fileName: "File.swift",
            lineNumber: 1
        )
    }
}

private final class SpyLogStore: LogStore, @unchecked Sendable {
    var isRecording = true
    let entries: [LogEntry]
    private(set) var removedEntryIDs: [LogEntry.ID] = []
    private(set) var removeAllCallCount = 0

    init(entries: [LogEntry]) {
        self.entries = entries
    }

    var entriesPublisher: AnyPublisher<[LogEntry], Never> {
        Just(entries).eraseToAnyPublisher()
    }

    func append(_ entry: LogEntry) {}

    func removeEntry(id: LogEntry.ID) {
        removedEntryIDs.append(id)
    }

    func removeAll() {
        removeAllCallCount += 1
    }
}
