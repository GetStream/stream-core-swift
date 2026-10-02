//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct LogDetailView: View {
    let entry: LogEntry
    @State private var content: LogDetailContent?
    @State private var mode = Mode.raw
    @StateObject private var json = LogJSONViewModel()

    enum Mode: Hashable {
        case raw
        case json
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    VStack(alignment: .leading, spacing: LogTokens.Spacing.md) {
                        LogDetailSummary(entry: entry)
                        actions
                    }
                    .padding(.horizontal, LogTokens.Spacing.md)
                    .padding(.top, LogTokens.Spacing.md)
                    .padding(.bottom, LogTokens.Spacing.xs)

                    if let content {
                        Section {
                            switch mode {
                            case .raw:
                                rawLog(content)
                            case .json:
                                jsonNodes
                            }
                        } header: {
                            contentHeader(hasJSON: !content.jsonTree.isEmpty)
                        }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(LogTokens.Spacing.md)
                    }
                }
            }
            .onChange(of: json.currentMatchID) { id in
                guard let id, mode == .json else { return }
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
        }
        .navigationTitle("Log Details")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: entry.id) {
            let entry = entry
            let content = await Task.detached(priority: .userInitiated) {
                LogDetailContent(entry: entry)
            }.value
            self.content = content
            json.load(content.jsonTree)
        }
    }

    private var actions: some View {
        HStack(spacing: LogTokens.Spacing.xs) {
            LogCopyButton(title: "Copy", systemImage: "doc.on.doc", text: content?.rawText ?? entry.rawText)
            if let curlCommand = content?.curlCommand {
                LogCopyButton(title: "cURL", systemImage: "terminal", text: curlCommand)
            }
            if let json = content?.json {
                LogCopyButton(title: "JSON", systemImage: "curlybraces", text: json)
            }
        }
    }

    private func contentHeader(hasJSON: Bool) -> some View {
        VStack(alignment: .leading, spacing: LogTokens.Spacing.xs) {
            if hasJSON {
                Picker("Format", selection: $mode) {
                    Text("Raw").tag(Mode.raw)
                    Text("JSON").tag(Mode.json)
                }
                .pickerStyle(.segmented)
                if mode == .json {
                    LogJSONToolbar(viewModel: json)
                }
            } else {
                Text("Raw Log")
                    .font(.headline)
                    .foregroundColor(LogTokens.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, LogTokens.Spacing.md)
        .padding(.vertical, LogTokens.Spacing.xs)
        .background(.bar)
    }

    private func rawLog(_ content: LogDetailContent) -> some View {
        VStack(alignment: .leading, spacing: LogTokens.Spacing.sm) {
            LogSelectableTextView(text: content.rawPreview.map { "\($0)…" } ?? content.rawText)
                .padding(LogTokens.Spacing.sm)
                .background(
                    LogTokens.Colors.backgroundSurfaceCard,
                    in: RoundedRectangle(cornerRadius: LogTokens.Radius.lg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LogTokens.Radius.lg)
                        .strokeBorder(LogTokens.Colors.borderDefault)
                )

            if content.rawPreview != nil {
                NavigationLink {
                    LogFullMessageView(message: content.rawText)
                } label: {
                    Label("View Full Log", systemImage: "text.alignleft")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(LogTokens.Colors.accentPrimary)
                }
            }
        }
        .padding(.horizontal, LogTokens.Spacing.md)
        .padding(.vertical, LogTokens.Spacing.xs)
    }

    @ViewBuilder
    private var jsonNodes: some View {
        let tree = json.tree
        ForEach(json.visibleIDs, id: \.self) { id in
            LogJSONNodeRow(
                node: tree.nodes[id],
                isExpanded: json.expandedIDs.contains(id),
                searchText: json.matchedText,
                isCurrentMatch: json.currentMatchID == id,
                toggle: { json.toggle(id) },
                jsonText: { tree.jsonText(for: id) }
            )
            .id(id)
            .padding(.horizontal, LogTokens.Spacing.xs)
        }
        Color.clear
            .frame(height: LogTokens.Spacing.md)
    }
}

@available(iOS 16.0, *)
private struct LogDetailSummary: View {
    let entry: LogEntry

    var body: some View {
        let httpRequest = entry.httpRequest
        VStack(alignment: .leading, spacing: LogTokens.Spacing.sm) {
            HStack(spacing: LogTokens.Spacing.xs) {
                if let httpRequest {
                    LogHTTPMethodBadge(method: httpRequest.method)
                    if let status = httpRequest.status {
                        LogHTTPStatusBadge(status: status, isError: entry.level >= .error)
                    }
                }
                LogLevelBadge(level: entry.level)
                Spacer(minLength: 0)
            }

            if let httpRequest {
                Text(httpRequest.url)
                    .font(.system(.footnote, design: .monospaced).weight(.medium))
                    .foregroundColor(LogTokens.Colors.textPrimary)
                    .textSelection(.enabled)
                if let error = httpRequest.error {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(LogTokens.Colors.textSecondary)
                        .textSelection(.enabled)
                }
            } else {
                Text(entry.message)
                    .font(.subheadline)
                    .foregroundColor(LogTokens.Colors.textPrimary)
                    .lineLimit(4)
            }

            Divider()
                .overlay(LogTokens.Colors.borderDefault)

            infoRows(hidingHTTPKeys: httpRequest != nil)
        }
        .padding(LogTokens.Spacing.md)
        .background(LogTokens.Colors.backgroundSurfaceCard, in: RoundedRectangle(cornerRadius: LogTokens.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: LogTokens.Radius.xl)
                .strokeBorder(LogTokens.Colors.borderDefault)
        )
    }

    private func infoRows(hidingHTTPKeys: Bool) -> some View {
        let hiddenKeys = hidingHTTPKeys ? Set(LogEntry.MetadataKey.httpKeys) : []
        let metadata = entry.metadata
            .filter { !hiddenKeys.contains($0.key) }
            .sorted { $0.key.rawValue < $1.key.rawValue }
        return VStack(alignment: .leading, spacing: LogTokens.Spacing.sm) {
            LogInfoRow(title: "Date") {
                Text(entry.date, format: .dateTime.day().month().year().hour().minute().second().secondFraction(.fractional(3)))
                    .monospacedDigit()
            }
            if !entry.subsystems.isEmpty {
                LogInfoRow(title: "Subsystems") {
                    HStack(spacing: LogTokens.Spacing.xxs) {
                        ForEach(entry.subsystems, id: \.self) { LogSubsystemTag(subsystem: $0) }
                    }
                }
            }
            if let fileName = entry.fileName {
                LogInfoRow(title: "File") {
                    Text(entry.lineNumber.map { "\(fileName):\($0)" } ?? fileName)
                }
            }
            if let functionName = entry.functionName {
                LogInfoRow(title: "Function") {
                    Text(functionName)
                }
            }
            if let threadName = entry.threadName {
                LogInfoRow(title: "Thread") {
                    Text(threadName)
                }
            }
            ForEach(metadata, id: \.key) { key, value in
                LogInfoRow(title: key.rawValue) {
                    Text(value)
                        .lineLimit(8)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

// Text views lay out a whole paragraph at once, and messages can contain very long lines,
// such as minified JSON responses, so the message is shown in lazily loaded chunks.
@available(iOS 16.0, *)
private struct LogFullMessageView: View {
    let message: String
    @State private var chunks: [String]?

    var body: some View {
        Group {
            if let chunks {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(chunks.indices, id: \.self) { index in
                            Text(chunks[index].isEmpty ? " " : chunks[index])
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(LogTokens.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .textSelection(.enabled)
                    .padding(LogTokens.Spacing.md)
                }
            } else {
                ProgressView()
            }
        }
        .task {
            let message = message
            chunks = await Task.detached(priority: .userInitiated) {
                LogMessageParser.chunks(of: message)
            }.value
        }
        .navigationTitle("Raw Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                LogCopyButton(title: "Copy", systemImage: "doc.on.doc", text: message)
            }
        }
    }
}

@available(iOS 16.0, *)
private struct LogInfoRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: LogTokens.Spacing.xxxs) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(LogTokens.Colors.textTertiary)
                .textCase(.uppercase)
            content
                .font(.footnote)
                .foregroundColor(LogTokens.Colors.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 16.0, *)
private struct LogCopyButton: View {
    let title: String
    let systemImage: String
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
            Label(isCopied ? "Copied" : title, systemImage: isCopied ? "checkmark" : systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundColor(isCopied ? LogTokens.Colors.accentSuccess : LogTokens.Colors.textPrimary)
                .padding(.horizontal, LogTokens.Spacing.sm)
                .padding(.vertical, LogTokens.Spacing.xs)
                .background(LogTokens.Colors.backgroundSurfaceDefault, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCopied ? "Copied" : "Copy \(title)")
    }
}
