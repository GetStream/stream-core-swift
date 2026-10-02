//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A thread-safe ``LogStore`` that keeps the most recent log entries in memory.
///
/// Appended entries are published in batches, at most once per ``publishInterval``.
/// Removals are published immediately.
public final class InMemoryLogStore: LogStore, @unchecked Sendable {
    /// The store displayed by ``LogListView`` by default.
    public static let shared = InMemoryLogStore()

    /// The maximum number of entries kept in memory. The oldest entries are dropped first.
    public let capacity: Int
    /// The minimum time between two publications of appended entries.
    public let publishInterval: TimeInterval

    private let queue = DispatchQueue(label: "io.getstream.logs-ui.in-memory-log-store")
    private let entriesSubject = CurrentValueSubject<[LogEntry], Never>([])
    private let recordingLock = NSLock()
    private var _isRecording = true
    // Only accessed on `queue`.
    private var buffer: [LogEntry] = []
    private var hasUnpublishedChanges = false
    private var isPublishScheduled = false

    public init(capacity: Int = 5000, publishInterval: TimeInterval = 0.25) {
        self.capacity = capacity
        self.publishInterval = publishInterval
    }

    // A store with the entries of the session that doesn't record new entries.
    convenience init(session: LogSession) {
        self.init(capacity: max(session.entries.count, 1))
        _isRecording = false
        buffer = session.entries
        entriesSubject.send(session.entries)
    }

    /// Whether new log entries are recorded. Defaults to `true`.
    public var isRecording: Bool {
        get { recordingLock.withLock { _isRecording } }
        set { recordingLock.withLock { _isRecording = newValue } }
    }

    public var entries: [LogEntry] {
        queue.sync {
            // Publishing pending changes first keeps `entries` and `entriesPublisher` consistent.
            publishIfNeeded()
            return entriesSubject.value
        }
    }

    public var entriesPublisher: AnyPublisher<[LogEntry], Never> {
        entriesSubject.eraseToAnyPublisher()
    }

    public func append(_ entry: LogEntry) {
        guard isRecording else { return }
        queue.async { [self] in
            buffer.append(entry)
            // Trimming in batches avoids shifting the whole buffer on every append.
            if buffer.count >= capacity + max(capacity / 10, 1) {
                buffer.removeFirst(buffer.count - capacity)
            }
            hasUnpublishedChanges = true
            schedulePublish()
        }
    }

    public func removeEntry(id: LogEntry.ID) {
        queue.async { [self] in
            buffer.removeAll { $0.id == id }
            hasUnpublishedChanges = true
            publishIfNeeded()
        }
    }

    public func removeAll() {
        queue.async { [self] in
            buffer.removeAll()
            hasUnpublishedChanges = true
            publishIfNeeded()
        }
    }

    private func schedulePublish() {
        guard !isPublishScheduled else { return }
        isPublishScheduled = true
        queue.asyncAfter(deadline: .now() + publishInterval) { [self] in
            isPublishScheduled = false
            publishIfNeeded()
        }
    }

    private func publishIfNeeded() {
        guard hasUnpublishedChanges else { return }
        hasUnpublishedChanges = false
        entriesSubject.send(buffer.count > capacity ? Array(buffer.suffix(capacity)) : buffer)
    }
}
