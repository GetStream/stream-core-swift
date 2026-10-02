//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A log entry displayed by ``LogListView``.
///
/// Only the date, level and message are required, so entries can be created from any logger.
/// Extra information that has no dedicated field, like a logger category or the details of an HTTP request,
/// can be added to ``metadata``.
public struct LogEntry: Identifiable, Hashable, Sendable {
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
    /// Additional values displayed with the entry and matched when searching.
    ///
    /// Entries with the HTTP keys, like ``MetadataKey/httpMethod`` and ``MetadataKey/httpURL``,
    /// are displayed as HTTP requests, with their status and bodies.
    public let metadata: [MetadataKey: String]

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
        metadata: [MetadataKey: String] = [:]
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
        metadata: [MetadataKey: String] = [:]
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

public extension LogEntry {
    /// The key of a value in ``LogEntry/metadata``.
    ///
    /// The predefined keys have the same raw values as the metadata keys of the StreamCore logger,
    /// so its metadata can be converted by raw value.
    struct MetadataKey: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }
    }
}

public extension LogEntry.MetadataKey {
    /// The method of an HTTP request, like `POST`.
    static let httpMethod: Self = "Method"
    /// The URL of an HTTP request.
    static let httpURL: Self = "URL"
    /// The status code of an HTTP response, like `200`.
    static let httpStatusCode: Self = "Status Code"
    /// The error of a failed HTTP request, like a connection error.
    static let httpError: Self = "Error"
    /// The body of an HTTP request.
    static let httpRequestBody: Self = "Request Body"
    /// The body of an HTTP response.
    static let httpResponseBody: Self = "Response Body"
    /// A cURL command that reproduces an HTTP request.
    static let httpCURL: Self = "cURL"
}

extension LogEntry.MetadataKey {
    static let httpKeys: [Self] = [.httpMethod, .httpURL, .httpStatusCode, .httpError, .httpRequestBody, .httpResponseBody, .httpCURL]
}

extension LogEntry {
    // The message followed by the metadata, one `Key: value` per line, like the StreamCore console output.
    var rawText: String {
        guard !metadata.isEmpty else { return message }
        let order = MetadataKey.httpKeys
        let rank = { (key: MetadataKey) in order.firstIndex(of: key) ?? order.count }
        let lines = metadata
            .sorted { lhs, rhs in
                let lhsRank = rank(lhs.key)
                let rhsRank = rank(rhs.key)
                return lhsRank == rhsRank ? lhs.key.rawValue < rhs.key.rawValue : lhsRank < rhsRank
            }
            .map { key, value in
                value.contains("\n") ? "\(key.rawValue):\n\(value)" : "\(key.rawValue): \(value)"
            }
        return ([message] + lines).joined(separator: "\n")
    }

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
