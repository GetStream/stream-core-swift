//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct LogDetailView: View {
    let entry: LogEntry
    private let curlCommand: String?
    private let json: String?

    init(entry: LogEntry) {
        self.entry = entry
        curlCommand = LogMessageParser.curlCommand(in: entry.message)
        json = LogMessageParser.json(in: entry.message)
    }

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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(entry.level.displayName, systemImage: entry.level.iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(entry.level.color)

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
                InfoRow(title: "Subsystems") {
                    HStack(spacing: 6) {
                        ForEach(entry.subsystems, id: \.self) { subsystem in
                            Text(subsystem)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                InfoRow(title: "File") {
                    Text("\(entry.fileName):\(entry.lineNumber)")
                }
                InfoRow(title: "Function") {
                    Text(entry.functionName)
                }
                if !entry.threadName.isEmpty {
                    InfoRow(title: "Thread") {
                        Text(entry.threadName)
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
