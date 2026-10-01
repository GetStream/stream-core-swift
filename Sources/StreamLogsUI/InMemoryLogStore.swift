//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A log entry displayed by ``LogListView``.
public struct LogEntry: Identifiable, Sendable {
    /// The severity of a log entry.
    public enum Level: Int, CaseIterable, Sendable {
        case debug
        case info
        case warning
        case error
    }

    public let id: UUID
    public let date: Date
    public let level: Level
    /// The names of the subsystems the entry belongs to.
    public let subsystems: [String]
    public let threadName: String
    public let functionName: String
    public let fileName: String
    public let lineNumber: UInt
    public let message: String

    public init(
        id: UUID = UUID(),
        date: Date,
        level: Level,
        subsystems: [String],
        threadName: String,
        functionName: String,
        fileName: String,
        lineNumber: UInt,
        message: String
    ) {
        self.id = id
        self.date = date
        self.level = level
        self.subsystems = subsystems
        self.threadName = threadName
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
        self.message = message
    }

    /// Creates an entry from the raw values reported by a logger.
    ///
    /// The thread name is trimmed of brackets and whitespace, the file name is reduced to its last path component,
    /// and the error, if any, is appended to the message.
    public init(
        date: Date,
        level: Level,
        subsystems: [String],
        threadName: String,
        functionName: StaticString,
        fileName: StaticString,
        lineNumber: UInt,
        message: String,
        error: Error?
    ) {
        self.init(
            date: date,
            level: level,
            subsystems: subsystems,
            threadName: threadName.trimmingCharacters(in: CharacterSet(charactersIn: "[] ")),
            functionName: String(describing: functionName),
            fileName: (String(describing: fileName) as NSString).lastPathComponent,
            lineNumber: lineNumber,
            message: error.map { "\(message)\n\($0)" } ?? message
        )
    }
}

/// A thread-safe, in-memory store of the log entries displayed by ``LogListView``.
///
/// The store does not depend on any logger. Feed it from the app, for example from a custom
/// `LogDestination` that maps each `LogDetails` to a ``LogEntry`` and calls ``append(_:)``.
public final class InMemoryLogStore: @unchecked Sendable {
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
    ///
    /// Log destinations feeding the store should check it before building entries, to avoid unnecessary work.
    public var isRecording: Bool {
        get { recordingLock.withLock { _isRecording } }
        set { recordingLock.withLock { _isRecording = newValue } }
    }

    /// The recorded entries, oldest first.
    public var entries: [LogEntry] {
        queue.sync { entriesSubject.value }
    }

    /// Publishes the recorded entries, oldest first, whenever they change.
    public var entriesPublisher: AnyPublisher<[LogEntry], Never> {
        entriesSubject.eraseToAnyPublisher()
    }

    /// Records the entry if ``isRecording`` is `true`.
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
