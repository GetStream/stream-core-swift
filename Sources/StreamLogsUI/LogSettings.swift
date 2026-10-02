//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Logger configuration that can be changed at runtime from ``LogSettingsView``.
///
/// Every destination, e.g. the console or the log viewer, has its own level and subsystems.
/// The settings are kept in memory only, so every launch starts from the defaults set with ``setDefaults(_:)``.
/// They don't depend on any logger. Use ``apply(_:)`` to update the app's logger whenever they change.
@MainActor
public final class LogSettings: ObservableObject {
    /// The settings displayed by ``LogSettingsView`` and ``LogListView`` by default.
    public static let shared = LogSettings()

    /// The destinations that logs are sent to.
    @Published public var destinations: [LogDestinationSettings] = [] {
        didSet { notifyHandlers() }
    }

    /// The levels that can be chosen in ``LogSettingsView`` and in the level filter of ``LogListView``.
    ///
    /// The level filter also lists any other level that has been recorded. Defaults to ``LogEntry/Level/standardLevels``.
    @Published public var availableLevels = LogEntry.Level.standardLevels

    /// The names of the subsystems that can be enabled or disabled, and chosen in the subsystem filter of ``LogListView``.
    ///
    /// The subsystem filter also lists any other subsystem that has been recorded.
    @Published public var availableSubsystems: [String] = [] {
        didSet { notifyHandlers() }
    }

    /// The destinations that receive logs.
    public var enabledDestinations: [LogDestinationSettings] {
        destinations.filter(\.isEnabled)
    }

    private var defaultDestinations: [LogDestinationSettings] = []
    private var isRestoringDefaults = false
    private var handlers: [@MainActor (LogSettings) -> Void] = []

    /// Creates settings without any destination.
    public init() {}

    /// The settings of the destination with the given identifier.
    public subscript(destinationID: String) -> LogDestinationSettings? {
        destinations.first { $0.id == destinationID }
    }

    /// The available subsystems that the given destination does not ignore.
    public func enabledSubsystems(for destination: LogDestinationSettings) -> [String] {
        availableSubsystems.filter { !destination.disabledSubsystems.contains($0) }
    }

    /// Sets the destinations used when the settings are reset, and applies them.
    public func setDefaults(_ destinations: [LogDestinationSettings]) {
        defaultDestinations = destinations
        reset()
    }

    /// Calls the handler with the current settings, and again whenever they change.
    public func apply(_ handler: @escaping @MainActor (LogSettings) -> Void) {
        handlers.append(handler)
        handler(self)
    }

    /// Restores the default values.
    public func reset() {
        isRestoringDefaults = true
        destinations = defaultDestinations
        isRestoringDefaults = false
        notifyHandlers()
    }

    private func notifyHandlers() {
        guard !isRestoringDefaults else { return }
        handlers.forEach { $0(self) }
    }
}
