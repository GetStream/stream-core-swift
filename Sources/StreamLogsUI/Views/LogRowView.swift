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
        let levelStyle = appearance.levelStyle(entry.level)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(entry.level.name, systemImage: levelStyle.iconName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(levelStyle.color)

                Spacer()

                Text(entry.date, format: .dateTime.hour().minute().second().secondFraction(.fractional(3)))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(entry.subsystems, id: \.self) { subsystem in
                    LogHighlightedText(text: subsystem, searchText: searchText)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(appearance.subsystemColor.opacity(0.1))
                        .foregroundColor(appearance.subsystemColor)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            if let sourceDescription = entry.sourceDescription {
                LogHighlightedText(text: sourceDescription, searchText: searchText)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)
            }

            LogHighlightedText(text: entry.message, searchText: searchText)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
