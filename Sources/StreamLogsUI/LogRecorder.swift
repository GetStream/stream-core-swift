//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A source of the log entries displayed by ``LogListView``.
///
/// ``InMemoryLogRecorder`` is the default implementation, which keeps the most recent entries in memory.
/// Implement it to display entries kept elsewhere, for example in a file that survives app launches.
/// How entries are recorded is up to each implementation.
public protocol LogRecorder: AnyObject, Sendable {
    /// Whether new log entries are recorded. The log viewer toggles it to pause and resume recording.
    var isRecording: Bool { get set }

    /// The recorded entries, oldest first.
    var entries: [LogEntry] { get }

    /// Publishes the recorded entries, oldest first, whenever they change.
    var entriesPublisher: AnyPublisher<[LogEntry], Never> { get }

    func removeEntry(id: LogEntry.ID)

    func removeAll()
}
