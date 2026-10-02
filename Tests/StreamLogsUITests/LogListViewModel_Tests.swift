//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamLogsUI
import XCTest

@MainActor
final class LogListViewModel_Tests: XCTestCase {
    private var recorder: InMemoryLogRecorder!
    private var subject: LogListViewModel!

    override func setUp() async throws {
        try await super.setUp()
        recorder = InMemoryLogRecorder()
        recorder.record(makeEntry(level: .debug, subsystems: ["HTTP"], message: "GET channels"))
        recorder.record(makeEntry(level: .error, subsystems: ["WebSocket"], message: "Socket disconnected"))
        recorder.record(makeEntry(level: .error, subsystems: ["Database", "Offline"], message: "Failed to save"))
        subject = makeViewModel(recorder: recorder)
    }

    override func tearDown() async throws {
        subject = nil
        recorder = nil
        try await super.tearDown()
    }

    func test_filteredEntries_withoutFilters_returnsNewestFirst() {
        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Failed to save", "Socket disconnected", "GET channels"])
        XCTAssertFalse(subject.isFiltering)
    }

    func test_initialFilter_isApplied() {
        subject = LogListViewModel(recorder: recorder, filter: LogFilter(levels: [.error], subsystems: ["Offline"]))

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Failed to save"])
        XCTAssertEqual(subject.selectedLevels, [.error])
        XCTAssertEqual(subject.selectedSubsystems, ["Offline"])
        XCTAssertTrue(subject.isFiltering)
    }

    func test_initialFilter_canBeCleared() async {
        subject = LogListViewModel(recorder: recorder, filter: LogFilter(levels: [.error]), searchDebounceInterval: .zero)

        subject.selectedLevels = []

        await waitForFilteredMessages(["Failed to save", "Socket disconnected", "GET channels"])
    }

    func test_filteredEntries_filtersByLevel() async {
        subject.selectedLevels = [.error]

        await waitForFilteredMessages(["Failed to save", "Socket disconnected"])
        XCTAssertTrue(subject.isFiltering)
    }

    func test_filteredEntries_levelExcludesOtherLevels() async {
        subject.selectedLevels = [.warning]

        await waitForFilteredMessages([])
    }

    func test_filteredEntries_multipleLevels_includesEachLevel() async {
        subject.selectedLevels = [.debug, .error]

        await waitForFilteredMessages(["Failed to save", "Socket disconnected", "GET channels"])
    }

    func test_availableLevels_includesSelectedLevelsWithoutEntries() {
        subject = LogListViewModel(recorder: recorder, filter: LogFilter(levels: [.warning]))

        XCTAssertEqual(subject.availableLevels, [.debug, .warning, .error])
    }

    func test_availableLevels_includesRecordedLevelsSortedBySeverity() {
        let security = LogEntry.Level(severity: 45, name: "SECURITY")
        recorder.record(LogEntry(level: security, message: "Token refreshed"))
        subject = makeViewModel(recorder: recorder)

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
        recorder.record(LogEntry(level: .info, message: "Tapped", metadata: ["category": "Navigation"]))
        subject = makeViewModel(recorder: recorder)

        subject.searchText = "navigation"

        await waitForFilteredMessages(["Tapped"])
    }

    func test_filteredEntries_updatesWhenRecorderChanges() async {
        recorder.record(makeEntry(level: .info, subsystems: ["HTTP"], message: "POST message"))

        await waitForFilteredMessages(["POST message", "Failed to save", "Socket disconnected", "GET channels"])
    }

    func test_availableSubsystems_includesRecordedAndSelectedSubsystemsSorted() async {
        subject.selectedSubsystems = ["Auth"]

        await waitForContent { $0.availableSubsystems == ["Auth", "Database", "HTTP", "Offline", "WebSocket"] }
    }

    func test_newEntries_whileNotFollowing_areHeldUntilShown() async {
        subject.isFollowingNewEntries = false

        recorder.record(makeEntry(level: .info, subsystems: ["HTTP"], message: "POST message"))

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
        recorder.record(makeEntry(level: .info, subsystems: ["HTTP"], message: "POST message"))
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

        subject.selectedLevels = [.error]

        await waitForFilteredMessages(["Failed to save", "Socket disconnected"])
    }

    func test_isRecording_updatesRecorder() {
        subject.isRecording = false

        XCTAssertFalse(recorder.isRecording)
    }

    func test_refreshRecordingState_readsRecorder() {
        recorder.isRecording = false

        subject.refreshRecordingState()

        XCTAssertFalse(subject.isRecording)
    }

    func test_customRecorder_providesEntriesAndReceivesRemovals() {
        let customRecorder = SpyLogRecorder(entries: [makeEntry(level: .info, subsystems: ["HTTP"], message: "Custom")])
        let subject = makeViewModel(recorder: customRecorder)

        subject.removeEntry(customRecorder.entries[0])
        subject.removeAll()

        XCTAssertEqual(subject.filteredEntries.map(\.message), ["Custom"])
        XCTAssertEqual(customRecorder.removedEntryIDs, [customRecorder.entries[0].id])
        XCTAssertEqual(customRecorder.removeAllCallCount, 1)
    }

    // MARK: - Private Helpers

    private func makeViewModel(recorder: any LogRecorder) -> LogListViewModel {
        LogListViewModel(recorder: recorder, searchDebounceInterval: .zero)
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

private final class SpyLogRecorder: LogRecorder, @unchecked Sendable {
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

    func removeEntry(id: LogEntry.ID) {
        removedEntryIDs.append(id)
    }

    func removeAll() {
        removeAllCallCount += 1
    }
}
