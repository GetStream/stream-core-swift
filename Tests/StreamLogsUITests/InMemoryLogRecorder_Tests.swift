//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamLogsUI
import Testing

struct InMemoryLogRecorder_Tests {
    private let subject = InMemoryLogRecorder(capacity: 3)

    @Test func recordKeepsEntry() throws {
        let entry = makeEntry(message: "Hello")

        subject.record(entry)

        let entries = subject.entries
        #expect(entries.count == 1)
        #expect(try #require(entries.first).id == entry.id)
    }

    @Test func recordIgnoresEntriesWhenNotRecording() {
        subject.isRecording = false

        subject.record(makeEntry(message: "Hello"))

        #expect(subject.entries.isEmpty)
    }

    @Test func recordDropsOldestEntriesWhenCapacityIsExceeded() {
        (1...5).forEach { subject.record(makeEntry(message: "\($0)")) }

        #expect(subject.entries.map(\.message) == ["3", "4", "5"])
    }

    @Test func removeEntriesUpdatesEntries() {
        let first = makeEntry(message: "1")
        subject.record(first)
        subject.record(makeEntry(message: "2"))

        subject.removeEntry(id: first.id)
        #expect(subject.entries.map(\.message) == ["2"])

        subject.removeAll()
        #expect(subject.entries.isEmpty)
    }

    @Test func recordedEntriesArePublishedTogether() async {
        let subject = InMemoryLogRecorder(capacity: 10, publishInterval: 0.05)

        (1...3).forEach { subject.record(makeEntry(message: "\($0)")) }

        let published = await subject.entriesPublisher.values.first { !$0.isEmpty }
        #expect(published?.map(\.message) == ["1", "2", "3"])
    }

    @Test func entriesNeverExceedCapacity() {
        let subject = InMemoryLogRecorder(capacity: 10)

        (1...25).forEach { subject.record(makeEntry(message: "\($0)")) }

        #expect(subject.entries.map(\.message) == (16...25).map { "\($0)" })
    }

    // MARK: - Private Helpers

    private func makeEntry(message: String) -> LogEntry {
        LogEntry(level: .debug, subsystems: ["Other"], message: message)
    }
}
