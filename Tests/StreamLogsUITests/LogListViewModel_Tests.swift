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
        subject = makeViewModel(store: store)
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

    func test_filteredEntries_filtersByMinimumLevel() async {
        subject.minimumLevel = .error

        await waitForFilteredMessages(["Failed to save", "Socket disconnected"])
        XCTAssertTrue(subject.isFiltering)
    }

    func test_filteredEntries_minimumLevelIncludesMoreSevereLevels() async {
        subject.minimumLevel = .warning

        await waitForFilteredMessages(["Failed to save", "Socket disconnected"])
    }

    func test_availableLevels_includesRecordedLevelsSortedBySeverity() {
        let security = LogEntry.Level(severity: 45, name: "SECURITY")
        store.append(LogEntry(level: security, message: "Token refreshed"))
        subject = makeViewModel(store: store)

        XCTAssertEqual(subject.availableLevels, [.debug, security, .error])
    }

    func test_filteredEntries_filtersBySubsystems() async {
        subject.selectedSubsystems = ["HTTP", "Offline"]

        await waitForFilteredMessages(["Failed to save", "GET channels"])
    }

    func test_filteredEntries_filtersBySearchText() async {
        subject.searchText = "socket"

        await waitForFilteredMessages(["Socket disconnected"])
    }

    func test_filteredEntries_searchMatchesSubsystem() async {
        subject.searchText = "http"

        await waitForFilteredMessages(["GET channels"])
    }

    func test_filteredEntries_searchMatchesMetadata() async {
        store.append(LogEntry(level: .info, message: "Tapped", metadata: ["category": "Navigation"]))
        subject = makeViewModel(store: store)

        subject.searchText = "navigation"

        await waitForFilteredMessages(["Tapped"])
    }

    func test_filteredEntries_updatesWhenStoreChanges() async {
        store.append(makeEntry(level: .info, subsystems: ["HTTP"], message: "POST message"))

        await waitForFilteredMessages(["POST message", "Failed to save", "Socket disconnected", "GET channels"])
    }

    func test_availableSubsystems_includesRecordedAndSelectedSubsystemsSorted() async {
        subject.selectedSubsystems = ["Auth"]

        await waitForContent { $0.availableSubsystems == ["Auth", "Database", "HTTP", "Offline", "WebSocket"] }
    }

    func test_newEntries_whileNotFollowing_areHeldUntilShown() async {
        subject.isFollowingNewEntries = false

        store.append(makeEntry(level: .info, subsystems: ["HTTP"], message: "POST message"))

        await waitForNewEntriesCount(1)
        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Failed to save", "Socket disconnected", "GET channels"])

        subject.showNewEntries()

        XCTAssertEqual(subject.newEntriesCount, 0)
        XCTAssertEqual(
            subject.filteredEntries.map(\.message),
            ["POST message", "Failed to save", "Socket disconnected", "GET channels"]
        )
    }

    func test_newEntries_whenFollowingResumes_areShown() async {
        subject.isFollowingNewEntries = false
        store.append(makeEntry(level: .info, subsystems: ["HTTP"], message: "POST message"))
        await waitForNewEntriesCount(1)

        subject.isFollowingNewEntries = true

        XCTAssertEqual(subject.newEntriesCount, 0)
        XCTAssertEqual(subject.filteredEntries.first?.message, "POST message")
    }

    func test_removedEntries_whileNotFollowing_areRemovedImmediately() async {
        subject.isFollowingNewEntries = false
        let removedEntry = subject.filteredEntries[2]

        subject.removeEntry(removedEntry)

        await waitForFilteredMessages(["Failed to save", "Socket disconnected"])
        XCTAssertEqual(subject.newEntriesCount, 0)
    }

    func test_filterChanges_whileNotFollowing_areAppliedImmediately() async {
        subject.isFollowingNewEntries = false

        subject.minimumLevel = .error

        await waitForFilteredMessages(["Failed to save", "Socket disconnected"])
    }

    func test_isRecording_updatesStore() {
        subject.isRecording = false

        XCTAssertFalse(store.isRecording)
    }

    func test_refreshRecordingState_readsStore() {
        store.isRecording = false

        subject.refreshRecordingState()

        XCTAssertFalse(subject.isRecording)
    }

    func test_customStore_providesEntriesAndReceivesRemovals() {
        let customStore = SpyLogStore(entries: [makeEntry(level: .info, subsystems: ["HTTP"], message: "Custom")])
        let subject = makeViewModel(store: customStore)

        subject.removeEntry(customStore.entries[0])
        subject.removeAll()

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Custom"])
        XCTAssertEqual(customStore.removedEntryIDs, [customStore.entries[0].id])
        XCTAssertEqual(customStore.removeAllCallCount, 1)
    }

    // MARK: - Private Helpers

    private func makeViewModel(store: any LogStore) -> LogListViewModel {
        LogListViewModel(store: store, searchDebounceInterval: .zero)
    }

    private func waitForFilteredMessages(
        _ messages: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await waitForContent { $0.filteredEntries.map(\.message) == messages }
        XCTAssertEqual(subject.filteredEntries.map(\.message), messages, file: file, line: line)
    }

    private func waitForContent(where predicate: @escaping (LogListViewModel.Content) -> Bool) async {
        await waitForValue(of: subject.$content, where: predicate)
    }

    private func waitForNewEntriesCount(_ count: Int) async {
        await waitForValue(of: subject.$newEntriesCount) { $0 == count }
    }

    private func waitForValue<Value>(
        of publisher: Published<Value>.Publisher,
        where predicate: @escaping (Value) -> Bool
    ) async {
        let expectation = expectation(description: "Value matches")
        let cancellable = publisher
            .first(where: predicate)
            .sink { _ in expectation.fulfill() }
        await fulfillment(of: [expectation], timeout: 2)
        cancellable.cancel()
    }

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
