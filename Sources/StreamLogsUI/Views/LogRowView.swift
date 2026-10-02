//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogRowView: View {
    let entry: LogEntry
    let searchText: String
    @Environment(\.logViewerAppearance) private var appearance

    var body: some View {
        VStack(alignment: .leading, spacing: LogTokens.Spacing.xs) {
            HStack(spacing: LogTokens.Spacing.xs) {
                LogLevelBadge(level: entry.level)

                Spacer(minLength: LogTokens.Spacing.xs)

                Text(entry.date, format: .dateTime.hour().minute().second().secondFraction(.fractional(3)))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(LogTokens.Colors.textTertiary)
            }

            LogHighlightedText(text: entry.message, searchText: searchText)
                .font(.subheadline)
                .foregroundColor(LogTokens.Colors.textPrimary)
                .lineLimit(3)

            footer
        }
        .padding(.leading, LogTokens.Spacing.sm)
        .background(alignment: .leading) {
            Capsule()
                .fill(appearance.levelStyle(entry.level).color)
                .frame(width: 3)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private static let maxVisibleSubsystems = 2

    private var footer: some View {
        HStack(spacing: LogTokens.Spacing.xxs) {
            ForEach(entry.subsystems.prefix(Self.maxVisibleSubsystems), id: \.self) { subsystem in
                LogSubsystemTag(subsystem: subsystem, searchText: searchText)
            }
            if entry.subsystems.count > Self.maxVisibleSubsystems {
                LogSubsystemTag(subsystem: "+\(entry.subsystems.count - Self.maxVisibleSubsystems)")
                    .accessibilityLabel("\(entry.subsystems.count - Self.maxVisibleSubsystems) more subsystems")
            }
            if let detail = entry.sourceDescription {
                LogHighlightedText(text: detail, searchText: searchText)
                    .font(.caption2)
                    .foregroundColor(LogTokens.Colors.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}
