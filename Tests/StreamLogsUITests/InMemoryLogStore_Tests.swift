//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamLogsUI
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

    @Test func appendedEntriesArePublishedTogether() async {
        let subject = InMemoryLogStore(capacity: 10, publishInterval: 0.05)

        (1...3).forEach { subject.append(makeEntry(message: "\($0)")) }

        let published = await subject.entriesPublisher.values.first { !$0.isEmpty }
        #expect(published?.map(\.message) == ["1", "2", "3"])
    }

    @Test func entriesNeverExceedCapacity() {
        let subject = InMemoryLogStore(capacity: 10)

        (1...25).forEach { subject.append(makeEntry(message: "\($0)")) }

        #expect(subject.entries.map(\.message) == (16...25).map { "\($0)" })
    }

    // MARK: - Private Helpers

    private func makeEntry(message: String) -> LogEntry {
        LogEntry(level: .debug, subsystems: ["Other"], message: message)
    }
}
