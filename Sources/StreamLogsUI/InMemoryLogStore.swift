//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A thread-safe ``LogStore`` that keeps the most recent log entries in memory.
public final class InMemoryLogStore: LogStore, @unchecked Sendable {
    /// The store displayed by ``LogListView`` by default.
    public static let shared = InMemoryLogStore()

    /// The maximum number of entries kept in memory. The oldest entries are dropped first.
    public let capacity: Int

    private let queue = DispatchQueue(label: "io.getstream.logs-ui.in-memory-log-store")
    private let entriesSubject = CurrentValueSubject<[LogEntry], Never>([])
    private let recordingLock = NSLock()
    private var _isRecording = true

    public init(capacity: Int = 5000) {
        self.capacity = capacity
    }

    /// Whether new log entries are recorded. Defaults to `true`.
    public var isRecording: Bool {
        get { recordingLock.withLock { _isRecording } }
        set { recordingLock.withLock { _isRecording = newValue } }
    }

    public var entries: [LogEntry] {
        queue.sync { entriesSubject.value }
    }

    public var entriesPublisher: AnyPublisher<[LogEntry], Never> {
        entriesSubject.eraseToAnyPublisher()
    }

    public func append(_ entry: LogEntry) {
        guard isRecording else { return }
        queue.async { [self] in
            var entries = entriesSubject.value
            entries.append(entry)
            if entries.count > capacity {
                entries.removeFirst(entries.count - capacity)
            }
            entriesSubject.send(entries)
        }
    }

    public func removeEntry(id: LogEntry.ID) {
        queue.async { [self] in
            entriesSubject.send(entriesSubject.value.filter { $0.id != id })
        }
    }

    public func removeAll() {
        queue.async { [self] in
            entriesSubject.send([])
        }
    }
}
