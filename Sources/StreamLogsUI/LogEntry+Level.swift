//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension LogEntry {
    /// The severity of a log entry.
    ///
    /// Levels are ordered by ``severity``. Besides the predefined levels, apps can define their own,
    /// for example `LogEntry.Level(severity: 45, name: "SECURITY")`.
    /// Levels with the same severity are equal, so give each custom level a severity that no other level uses.
    struct Level: Hashable, Comparable, Sendable, CustomStringConvertible {
        /// The rank of the level. Higher values are more severe.
        public let severity: Int
        /// The name displayed for the level, e.g. `WARNING`.
        public let name: String

        public init(severity: Int, name: String) {
            self.severity = severity
            self.name = name
        }

        public static let trace = Level(severity: 0, name: "TRACE")
        public static let debug = Level(severity: 10, name: "DEBUG")
        public static let info = Level(severity: 20, name: "INFO")
        public static let notice = Level(severity: 30, name: "NOTICE")
        public static let warning = Level(severity: 40, name: "WARNING")
        public static let error = Level(severity: 50, name: "ERROR")
        public static let critical = Level(severity: 60, name: "CRITICAL")

        /// The predefined levels, from the least to the most severe.
        public static let standardLevels: [Level] = [.trace, .debug, .info, .notice, .warning, .error, .critical]

        public var description: String { name }

        public static func == (lhs: Level, rhs: Level) -> Bool {
            lhs.severity == rhs.severity
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(severity)
        }

        public static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.severity < rhs.severity
        }
    }
}
