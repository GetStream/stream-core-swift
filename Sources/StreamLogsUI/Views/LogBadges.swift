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
    // Whether the live dot pulses when the badge appears, for messages that were just received or sent.
    var pulses = false

    var body: some View {
        LogBadge(color: LogTokens.Colors.webSocket) {
            LogLiveDot(color: LogTokens.Colors.webSocket, pulses: pulses)
            Text("WS")
                .font(.caption2.weight(.bold).monospaced())
            Image(systemName: direction == .received ? "arrow.down" : "arrow.up")
                .font(.caption2.weight(.bold))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(direction == .received ? "Received WebSocket message" : "Sent WebSocket message")
    }
}

@available(iOS 16.0, *)
private struct LogLiveDot: View {
    let color: Color
    let pulses: Bool
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .background {
                Circle()
                    .fill(color)
                    .scaleEffect(isPulsing ? 2.2 : 1)
                    .opacity(pulses && !isPulsing ? 0.5 : 0)
            }
            .accessibilityHidden(true)
            .onAppear {
                guard pulses, !reduceMotion else { return }
                withAnimation(.easeOut(duration: 0.9).repeatCount(3, autoreverses: false)) {
                    isPulsing = true
                }
            }
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
    // HTTP requests are colored by their status, WebSocket messages by their own color
    // unless they are warnings or errors, and other entries by their level.
    func accentColor(appearance: LogViewerAppearance) -> Color {
        if let status = httpRequest?.status {
            return status.color(isError: level >= .error)
        }
        if level < .warning, webSocketMessage != nil {
            return LogTokens.Colors.webSocket
        }
        return appearance.levelStyle(level).color
    }
}
