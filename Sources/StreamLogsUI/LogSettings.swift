//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Logger configuration that can be changed at runtime from ``LogSettingsView``.
///
/// The settings are kept in memory only, so every launch starts from the defaults set with ``setDefaults(isEnabled:level:disabledSubsystems:)``.
/// They don't depend on any logger. Use ``apply(_:)`` to update the app's logger whenever they change.
@MainActor
public final class LogSettings: ObservableObject {
    /// The settings displayed by ``LogSettingsView`` and ``LogListView`` by default.
    public static let shared = LogSettings()

    /// Whether logging is enabled. When `false`, no log should be processed.
    @Published public var isEnabled = true {
        didSet { notifyHandlers() }
    }

    /// The minimum level of the logs.
    @Published public var level = LogEntry.Level.warning {
        didSet { notifyHandlers() }
    }

    /// The subsystems whose logs are ignored.
    @Published public var disabledSubsystems: Set<String> = [] {
        didSet { notifyHandlers() }
    }

    /// The levels that can be chosen in ``LogSettingsView``. Defaults to ``LogEntry/Level/standardLevels``.
    @Published public var availableLevels = LogEntry.Level.standardLevels

    /// The names of the subsystems that can be enabled or disabled.
    @Published public var availableSubsystems: [String] = [] {
        didSet { notifyHandlers() }
    }

    /// The available subsystems that are not disabled.
    public var enabledSubsystems: [String] {
        availableSubsystems.filter { !disabledSubsystems.contains($0) }
    }

    private var defaultIsEnabled = true
    private var defaultLevel = LogEntry.Level.warning
    private var defaultDisabledSubsystems: Set<String> = []
    private var isRestoringDefaults = false
    private var handlers: [@MainActor (LogSettings) -> Void] = []

    /// Creates settings with logging enabled at the warning level for all subsystems.
    public init() {}

    /// Sets the values used when the settings are reset, and applies them.
    public func setDefaults(isEnabled: Bool = true, level: LogEntry.Level, disabledSubsystems: Set<String> = []) {
        defaultIsEnabled = isEnabled
        defaultLevel = level
        defaultDisabledSubsystems = disabledSubsystems
        reset()
    }

    /// Calls the handler with the current settings, and again whenever they change.
    public func apply(_ handler: @escaping @MainActor (LogSettings) -> Void) {
        handlers.append(handler)
        handler(self)
    }

    public func setSubsystem(_ subsystem: String, isEnabled: Bool) {
        if isEnabled {
            disabledSubsystems.remove(subsystem)
        } else {
            disabledSubsystems.insert(subsystem)
        }
    }

    /// Restores the default values.
    public func reset() {
        isRestoringDefaults = true
        isEnabled = defaultIsEnabled
        level = defaultLevel
        disabledSubsystems = defaultDisabledSubsystems
        isRestoringDefaults = false
        notifyHandlers()
    }

    private func notifyHandlers() {
        guard !isRestoringDefaults else { return }
        handlers.forEach { $0(self) }
    }
}
