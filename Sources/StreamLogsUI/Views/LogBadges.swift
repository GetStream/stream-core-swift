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
struct LogHTTPMethodBadge: View {
    let method: String

    var body: some View {
        LogBadge(color: LogTokens.Colors.textPrimary, background: LogTokens.Colors.accentNeutral.opacity(0.16)) {
            Text(method)
                .font(.caption2.weight(.bold).monospaced())
        }
        .accessibilityLabel("Method \(method)")
    }
}

@available(iOS 16.0, *)
struct LogWebSocketBadge: View {
    let direction: LogWebSocketMessage.Direction

    var body: some View {
        LogBadge(color: LogTokens.Colors.textPrimary, background: LogTokens.Colors.accentNeutral.opacity(0.16)) {
            Image(systemName: direction == .received ? "arrow.down" : "arrow.up")
                .font(.caption2.weight(.bold))
            Text("WS")
                .font(.caption2.weight(.bold).monospaced())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(direction == .received ? "Received WebSocket message" : "Sent WebSocket message")
    }
}

@available(iOS 16.0, *)
struct LogHTTPStatusBadge: View {
    let status: LogHTTPRequest.Status
    // Failed requests are only shown as errors when logged as errors, as cancelled requests also fail.
    let isError: Bool

    var body: some View {
        let color = status.color(isError: isError)
        LogBadge(color: color) {
            if let code = status.code {
                Text(String(code))
                    .font(.caption2.weight(.bold).monospacedDigit())
            }
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(status.reasonPhrase)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status \(status.code.map { "\($0) " } ?? "")\(status.reasonPhrase)")
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

extension LogHTTPRequest.Status {
    func color(isError: Bool) -> Color {
        switch self {
        case .success: LogTokens.Colors.accentSuccess
        case .informational, .redirection: LogTokens.Colors.accentPrimary
        case .clientError: LogTokens.Colors.accentWarning
        case .serverError: LogTokens.Colors.accentError
        case .failed: isError ? LogTokens.Colors.accentError : LogTokens.Colors.accentNeutral
        }
    }
}

extension LogEntry {
    // HTTP requests are colored by their status, other entries by their level.
    func accentColor(appearance: LogViewerAppearance) -> Color {
        httpRequest?.status?.color(isError: level >= .error) ?? appearance.levelStyle(level).color
    }
}
