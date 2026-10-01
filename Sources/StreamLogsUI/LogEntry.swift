//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A log entry displayed by ``LogListView``.
///
/// Only the date, level and message are required, so entries can be created from any logger.
/// Extra information that has no dedicated field, like a logger category, can be added to ``metadata``.
public struct LogEntry: Identifiable, Hashable, Sendable {
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
    public let message: String
    public let threadName: String?
    public let functionName: String?
    public let fileName: String?
    public let lineNumber: UInt?
    /// Additional key-value pairs displayed with the entry and matched when searching.
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        level: Level,
        subsystems: [String] = [],
        message: String,
        threadName: String? = nil,
        functionName: String? = nil,
        fileName: String? = nil,
        lineNumber: UInt? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.date = date
        self.level = level
        self.subsystems = subsystems
        self.message = message
        self.threadName = threadName
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
        self.metadata = metadata
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
        error: Error?,
        metadata: [String: String] = [:]
    ) {
        let threadName = threadName.trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
        self.init(
            date: date,
            level: level,
            subsystems: subsystems,
            message: error.map { "\(message)\n\($0)" } ?? message,
            threadName: threadName.isEmpty ? nil : threadName,
            functionName: String(describing: functionName),
            fileName: (String(describing: fileName) as NSString).lastPathComponent,
            lineNumber: lineNumber,
            metadata: metadata
        )
    }

    // Entries are immutable and uniquely identified, so comparing identifiers avoids hashing long messages.
    public static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension LogEntry {
    /// The source location, e.g. `[File.swift:42] function()`, or `nil` when the entry has none.
    var sourceDescription: String? {
        let location = fileName.map { fileName in lineNumber.map { "\(fileName):\($0)" } ?? fileName }
        switch (location, functionName) {
        case let (location?, functionName?):
            return "[\(location)] \(functionName)"
        case let (location?, nil):
            return "[\(location)]"
        case let (nil, functionName?):
            return functionName
        case (nil, nil):
            return nil
        }
    }
}
