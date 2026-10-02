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
    @State private var isSummaryExpanded = false
    @StateObject private var json = LogJSONViewModel()

    enum Mode: Hashable {
        case raw
        case json
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    LogDetailSummary(entry: entry, isExpanded: $isSummaryExpanded)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                LogCopyButton(options: content?.copyOptions ?? [])
            }
        }
        .task(id: entry.id) {
            let entry = entry
            let content = await Task.detached(priority: .userInitiated) {
                LogDetailContent(entry: entry)
            }.value
            self.content = content
            json.load(content.jsonTree)
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
    @Binding var isExpanded: Bool

    var body: some View {
        let httpRequest = entry.httpRequest
        VStack(alignment: .leading, spacing: LogTokens.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: LogTokens.Spacing.xs) {
                    if let httpRequest {
                        LogHTTPMethodBadge(method: httpRequest.method)
                        if let status = httpRequest.status {
                            LogHTTPStatusBadge(status: status, isError: entry.level >= .error)
                        }
                    }
                    LogLevelBadge(level: entry.level)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(LogTokens.Colors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(isExpanded ? "Hides the log details" : "Shows the log details")

            if let httpRequest {
                Text(httpRequest.url)
                    .font(.system(.footnote, design: .monospaced).weight(.medium))
                    .foregroundColor(LogTokens.Colors.textPrimary)
                    .lineLimit(isExpanded ? nil : 2)
                    .textSelection(.enabled)
                if isExpanded, let error = httpRequest.error {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(LogTokens.Colors.textSecondary)
                        .textSelection(.enabled)
                }
            } else {
                Text(entry.message)
                    .font(.subheadline)
                    .foregroundColor(LogTokens.Colors.textPrimary)
                    .lineLimit(isExpanded ? 8 : 2)
            }

            if isExpanded {
                Divider()
                    .overlay(LogTokens.Colors.borderDefault)

                infoRows(hidingHTTPKeys: httpRequest != nil)
            }
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
                    LogFlowLayout(spacing: LogTokens.Spacing.xxs) {
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
                LogCopyButton(options: [LogCopyOption(title: "Raw", text: message)])
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

// Asks which format to copy when there are several, and copies the only one directly otherwise.
@available(iOS 16.0, *)
private struct LogCopyButton: View {
    let options: [LogCopyOption]
    @State private var isShowingOptions = false
    @State private var isCopied = false

    var body: some View {
        Button {
            if options.count == 1 {
                copy(options[0])
            } else {
                isShowingOptions = true
            }
        } label: {
            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .foregroundColor(isCopied ? LogTokens.Colors.accentSuccess : LogTokens.Colors.accentPrimary)
        }
        .disabled(options.isEmpty)
        .accessibilityLabel(isCopied ? "Copied" : "Copy")
        .confirmationDialog("Copy as", isPresented: $isShowingOptions, titleVisibility: .visible) {
            ForEach(options) { option in
                Button(option.title) { copy(option) }
            }
        }
    }

    private func copy(_ option: LogCopyOption) {
        UIPasteboard.general.string = option.text
        isCopied = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isCopied = false
        }
    }
}
