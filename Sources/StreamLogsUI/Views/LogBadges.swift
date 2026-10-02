//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogBadge<Content: View>: View {
    let color: Color
    var background: Color?
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: LogTokens.Spacing.xxs) {
            content
        }
        .font(.caption2.weight(.semibold))
        .foregroundColor(color)
        .padding(.horizontal, LogTokens.Spacing.xs)
        .padding(.vertical, LogTokens.Spacing.xxxs)
        .background(background ?? color.opacity(0.12), in: Capsule())
    }
}

@available(iOS 16.0, *)
struct LogLevelBadge: View {
    let level: LogEntry.Level
    @Environment(\.logViewerAppearance) private var appearance

    var body: some View {
        let style = appearance.levelStyle(level)
        LogBadge(color: style.color) {
            Image(systemName: style.iconName)
                .accessibilityHidden(true)
            Text(level.name)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(level.name)")
    }
}

@available(iOS 16.0, *)
struct LogSubsystemTag: View {
    let subsystem: String
    var searchText = ""
    @Environment(\.logViewerAppearance) private var appearance

    var body: some View {
        LogHighlightedText(text: subsystem, searchText: searchText)
            .font(.caption2.weight(.medium))
            .foregroundColor(appearance.subsystemColor)
            .lineLimit(1)
            .padding(.horizontal, LogTokens.Spacing.xs - 2)
            .padding(.vertical, LogTokens.Spacing.xxxs)
            .background(appearance.subsystemColor.opacity(0.1), in: RoundedRectangle(cornerRadius: LogTokens.Radius.sm))
            .fixedSize()
    }
}
