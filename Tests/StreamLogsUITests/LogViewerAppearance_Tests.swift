//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamLogsUI
import SwiftUI
import Testing

struct LogViewerAppearance_Tests {
    @Test(arguments: [
        (LogEntry.Level.trace, LogTokens.Colors.accentTrace),
        (.debug, LogTokens.Colors.accentNeutral),
        (.info, LogTokens.Colors.accentPrimary),
        (.notice, LogTokens.Colors.accentInfo),
        (.warning, LogTokens.Colors.accentWarning),
        (.error, LogTokens.Colors.accentError),
        (.critical, LogTokens.Colors.accentCritical)
    ])
    func defaultLevelStyleColorsStandardLevels(level: LogEntry.Level, color: Color) {
        #expect(LogViewerAppearance.defaultLevelStyle(for: level).color == color)
    }

    @Test func defaultLevelStyleUsesClosestLowerStandardLevel() {
        let security = LogEntry.Level(severity: 45, name: "SECURITY")

        let style = LogViewerAppearance.defaultLevelStyle(for: security)

        #expect(style.color == LogTokens.Colors.accentWarning)
        #expect(style.iconName == "exclamationmark.triangle")
    }

    @Test func customLevelStyleIsUsed() {
        let subject = LogViewerAppearance(levelStyle: { _ in .init(color: .mint, iconName: "star") })

        let style = subject.levelStyle(.error)

        #expect(style.color == .mint)
        #expect(style.iconName == "star")
    }
}
