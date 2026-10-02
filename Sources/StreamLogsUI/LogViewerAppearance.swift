//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The colors and icons used by the log viewer.
///
/// Apply it with the `logViewerAppearance(_:)` view modifier or pass it to ``LogViewer/present(recorder:settings:appearance:filter:)``.
public struct LogViewerAppearance: Sendable {
    /// How a log level is displayed.
    public struct LevelStyle: Sendable {
        public var color: Color
        /// The name of the SF Symbol displayed next to the level name.
        public var iconName: String

        public init(color: Color, iconName: String) {
            self.color = color
            self.iconName = iconName
        }
    }

    /// Returns the style of a level. Defaults to ``defaultLevelStyle(for:)``.
    public var levelStyle: @Sendable (LogEntry.Level) -> LevelStyle
    /// The color of subsystem tags.
    public var subsystemColor: Color
    /// The background color of text that matches the search.
    public var highlightColor: Color

    public init(
        levelStyle: @escaping @Sendable (LogEntry.Level) -> LevelStyle = Self.defaultLevelStyle(for:),
        subsystemColor: Color = LogTokens.Colors.accentNeutral,
        highlightColor: Color = LogTokens.Colors.highlight
    ) {
        self.levelStyle = levelStyle
        self.subsystemColor = subsystemColor
        self.highlightColor = highlightColor
    }

    /// The default style of a level, based on the predefined level with the closest lower or equal severity.
    public static func defaultLevelStyle(for level: LogEntry.Level) -> LevelStyle {
        switch level {
        case ..<LogEntry.Level.debug: LevelStyle(color: LogTokens.Colors.accentTrace, iconName: "text.alignleft")
        case ..<LogEntry.Level.info: LevelStyle(color: LogTokens.Colors.accentNeutral, iconName: "ant")
        case ..<LogEntry.Level.notice: LevelStyle(color: LogTokens.Colors.accentPrimary, iconName: "info.circle")
        case ..<LogEntry.Level.warning: LevelStyle(color: LogTokens.Colors.accentInfo, iconName: "bell")
        case ..<LogEntry.Level.error: LevelStyle(color: LogTokens.Colors.accentWarning, iconName: "exclamationmark.triangle")
        case ..<LogEntry.Level.critical: LevelStyle(color: LogTokens.Colors.accentError, iconName: "xmark.octagon")
        default: LevelStyle(color: LogTokens.Colors.accentCritical, iconName: "flame")
        }
    }
}

public extension View {
    /// Sets the appearance of the log viewer views in this view hierarchy.
    func logViewerAppearance(_ appearance: LogViewerAppearance) -> some View {
        environment(\.logViewerAppearance, appearance)
    }
}

extension EnvironmentValues {
    var logViewerAppearance: LogViewerAppearance {
        get { self[LogViewerAppearanceKey.self] }
        set { self[LogViewerAppearanceKey.self] = newValue }
    }
}

private struct LogViewerAppearanceKey: EnvironmentKey {
    static let defaultValue = LogViewerAppearance()
}
