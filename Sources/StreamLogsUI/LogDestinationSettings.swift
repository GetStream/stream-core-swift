//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The configuration of one of the destinations listed in ``LogSettingsView``, e.g. the console or the log viewer.
public struct LogDestinationSettings: Identifiable, Equatable, Sendable {
    /// Identifies the destination when reading the settings, e.g. `"console"`.
    public let id: String
    /// The name displayed in ``LogSettingsView``.
    public var name: String
    /// Whether the destination receives logs.
    public var isEnabled: Bool
    /// The minimum level of the logs the destination receives.
    public var level: LogEntry.Level
    /// The subsystems whose logs the destination ignores.
    public var disabledSubsystems: Set<String>

    public init(
        id: String,
        name: String,
        isEnabled: Bool = true,
        level: LogEntry.Level,
        disabledSubsystems: Set<String> = []
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.level = level
        self.disabledSubsystems = disabledSubsystems
    }
}
