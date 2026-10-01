//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamLogsUI
import SwiftUI
import Testing

struct LogViewerAppearance_Tests {
    @Test(arguments: [
        (LogEntry.Level.trace, Color.gray),
        (.debug, .purple),
        (.info, .blue),
        (.notice, .teal),
        (.warning, .orange),
        (.error, .red),
        (.critical, .pink)
    ])
    func defaultLevelStyleColorsStandardLevels(level: LogEntry.Level, color: Color) {
        #expect(LogViewerAppearance.defaultLevelStyle(for: level).color == color)
    }

    @Test func defaultLevelStyleUsesClosestLowerStandardLevel() {
        let security = LogEntry.Level(severity: 45, name: "SECURITY")

        let style = LogViewerAppearance.defaultLevelStyle(for: security)

        #expect(style.color == .orange)
        #expect(style.iconName == "exclamationmark.triangle")
    }

    @Test func customLevelStyleIsUsed() {
        let subject = LogViewerAppearance(levelStyle: { _ in .init(color: .mint, iconName: "star") })

        let style = subject.levelStyle(.error)

        #expect(style.color == .mint)
        #expect(style.iconName == "star")
    }
}
