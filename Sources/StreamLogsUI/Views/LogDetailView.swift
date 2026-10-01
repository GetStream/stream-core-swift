//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct LogDetailView: View {
    let entry: LogEntry
    @State private var curlCommand: String?
    @State private var json: String?
    @Environment(\.logViewerAppearance) private var appearance

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                message
            }
            .padding()
        }
        .navigationTitle("Log Details")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: entry.id) {
            let message = entry.message
            let parsed = await Task.detached(priority: .userInitiated) {
                (LogMessageParser.curlCommand(in: message), LogMessageParser.json(in: message))
            }.value
            curlCommand = parsed.0
            json = parsed.1
        }
    }

    private var header: some View {
        let levelStyle = appearance.levelStyle(entry.level)
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(entry.level.name, systemImage: levelStyle.iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(levelStyle.color)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.date, format: .dateTime.day().month().year())
                        .font(.subheadline)
                    Text(entry.date, format: .dateTime.hour().minute().second().secondFraction(.fractional(3)))
                        .font(.caption.monospacedDigit())
                }
                .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                if !entry.subsystems.isEmpty {
                    InfoRow(title: "Subsystems") {
                        HStack(spacing: 6) {
                            ForEach(entry.subsystems, id: \.self) { subsystem in
                                Text(subsystem)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(appearance.subsystemColor.opacity(0.1))
                                    .foregroundColor(appearance.subsystemColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                if let fileName = entry.fileName {
                    InfoRow(title: "File") {
                        Text(entry.lineNumber.map { "\(fileName):\($0)" } ?? fileName)
                    }
                }
                if let functionName = entry.functionName {
                    InfoRow(title: "Function") {
                        Text(functionName)
                    }
                }
                if let threadName = entry.threadName {
                    InfoRow(title: "Thread") {
                        Text(threadName)
                    }
                }
                ForEach(entry.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    InfoRow(title: key) {
                        Text(value)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var message: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("Log Message")
                    .font(.headline)

                Spacer()

                CopyButton(title: "Copy", systemImage: "doc.on.doc", tint: .blue, text: entry.message)
                if let curlCommand {
                    CopyButton(title: "cURL", systemImage: "terminal", tint: .orange, text: curlCommand)
                }
                if let json {
                    CopyButton(title: "JSON", systemImage: "curlybraces", tint: .purple, text: json)
                }
            }

            LogSelectableTextView(text: entry.message)
                .padding()
                .background(Color(.systemBackground))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 1))
        }
    }
}

@available(iOS 16.0, *)
private struct InfoRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            content
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 16.0, *)
private struct CopyButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let text: String
    @State private var isCopied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            isCopied = true
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                isCopied = false
            }
        } label: {
            Label(isCopied ? "Copied!" : title, systemImage: isCopied ? "checkmark" : systemImage)
                .font(.caption)
                .foregroundColor(isCopied ? .green : tint)
        }
        .accessibilityLabel(isCopied ? "Copied" : "Copy \(title)")
    }
}
