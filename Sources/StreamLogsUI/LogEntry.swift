//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

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
