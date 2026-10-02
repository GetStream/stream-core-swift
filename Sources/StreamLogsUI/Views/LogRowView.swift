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
        let http = entry.httpRequest
        let webSocket = http == nil ? entry.webSocketMessage : nil
        VStack(alignment: .leading, spacing: LogTokens.Spacing.xs) {
            HStack(spacing: LogTokens.Spacing.xs) {
                if let http {
                    LogHTTPMethodBadge(method: http.method)
                    if let status = http.status {
                        LogHTTPStatusBadge(status: status, isError: entry.level >= .error)
                    }
                } else if let webSocket {
                    LogWebSocketBadge(
                        direction: webSocket.direction,
                        pulses: Date().timeIntervalSince(entry.date) < Self.livePulseDuration
                    )
                } else {
                    LogLevelBadge(level: entry.level)
                }

                Spacer(minLength: LogTokens.Spacing.xs)

                Text(entry.date, format: .dateTime.hour().minute().second().secondFraction(.fractional(3)))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(LogTokens.Colors.textTertiary)
            }

            if let http {
                LogHighlightedText(text: http.path, searchText: searchText)
                    .font(.subheadline.weight(.medium).monospaced())
                    .foregroundColor(LogTokens.Colors.textPrimary)
                    .lineLimit(2)
                if let error = http.error {
                    LogHighlightedText(text: error, searchText: searchText)
                        .font(.footnote)
                        .foregroundColor(LogTokens.Colors.textSecondary)
                        .lineLimit(2)
                }
            } else if let eventType = webSocket?.eventType {
                LogHighlightedText(text: eventType, searchText: searchText)
                    .font(.subheadline.weight(.medium).monospaced())
                    .foregroundColor(LogTokens.Colors.textPrimary)
                    .lineLimit(2)
            } else {
                LogHighlightedText(text: entry.message, searchText: searchText)
                    .font(.subheadline)
                    .foregroundColor(LogTokens.Colors.textPrimary)
                    .lineLimit(3)
            }

            footer(http: http)
        }
        .padding(.leading, LogTokens.Spacing.sm)
        .background(alignment: .leading) {
            Capsule()
                .fill(entry.accentColor(appearance: appearance))
                .frame(width: 3)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private static let maxVisibleSubsystems = 2
    // WebSocket messages logged less than this long ago pulse when their row appears.
    private static let livePulseDuration: TimeInterval = 3

    private func footer(http: LogHTTPRequest?) -> some View {
        HStack(spacing: LogTokens.Spacing.xxs) {
            ForEach(entry.subsystems.prefix(Self.maxVisibleSubsystems), id: \.self) { subsystem in
                LogSubsystemTag(subsystem: subsystem, searchText: searchText)
            }
            if entry.subsystems.count > Self.maxVisibleSubsystems {
                LogSubsystemTag(subsystem: "+\(entry.subsystems.count - Self.maxVisibleSubsystems)")
                    .accessibilityLabel("\(entry.subsystems.count - Self.maxVisibleSubsystems) more subsystems")
            }
            if let detail = http.map({ $0.host ?? $0.url }) ?? entry.sourceDescription {
                LogHighlightedText(text: detail, searchText: searchText)
                    .font(.caption2)
                    .foregroundColor(LogTokens.Colors.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}
