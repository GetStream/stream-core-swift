//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A store of the log entries displayed by ``LogListView``.
///
/// Stores don't depend on any logger. Feed them from the app, for example from a custom log destination
/// that maps each logged message to a ``LogEntry`` and calls ``append(_:)``.
/// ``InMemoryLogStore`` is the default implementation.
public protocol LogStore: AnyObject, Sendable {
    /// Whether new log entries are recorded.
    ///
    /// Log destinations feeding the store should check it before building entries, to avoid unnecessary work.
    var isRecording: Bool { get set }

    /// The recorded entries, oldest first.
    var entries: [LogEntry] { get }

    /// Publishes the recorded entries, oldest first, whenever they change.
    var entriesPublisher: AnyPublisher<[LogEntry], Never> { get }

    /// Records the entry if ``isRecording`` is `true`.
    func append(_ entry: LogEntry)

    func removeEntry(id: LogEntry.ID)

    func removeAll()
}
