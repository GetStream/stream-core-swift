//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogRowView: View {
    let entry: LogEntry
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(entry.level.displayName, systemImage: entry.level.iconName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(entry.level.color)

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
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            LogHighlightedText(
                text: "[\(entry.fileName):\(entry.lineNumber)] \(entry.functionName)",
                searchText: searchText
            )
            .font(.caption.weight(.medium))
            .foregroundColor(.primary)

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
