//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The entries shown by ``LogListView``.
public struct LogFilter: Equatable, Sendable {
    /// Text that the message, source, subsystems or metadata of an entry must contain. Empty matches every entry.
    public var searchText: String
    /// The least severe level shown. `nil` shows every level.
    public var minimumLevel: LogEntry.Level?
    /// Shows only entries in at least one of these subsystems. Empty shows every subsystem.
    public var subsystems: Set<String>

    public init(searchText: String = "", minimumLevel: LogEntry.Level? = nil, subsystems: Set<String> = []) {
        self.searchText = searchText
        self.minimumLevel = minimumLevel
        self.subsystems = subsystems
    }
}
