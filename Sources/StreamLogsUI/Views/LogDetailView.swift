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
    @State private var isSummaryExpanded = true
    @StateObject private var json = LogJSONViewModel()
    @StateObject private var raw = LogRawTextViewModel()
    @Environment(\.logViewerAppearance) private var appearance

    enum Mode: Hashable {
        case raw
        case json
    }

    private struct RawChunkID: Hashable {
        let index: Int
    }

    // Keeps tapped JSON nodes in the upper part of the screen, where they were most likely tapped.
    private static let scrollAnchor = UnitPoint(x: 0.5, y: 0.3)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    LogDetailSummary(entry: entry, isExpanded: $isSummaryExpanded)
                        .padding(LogTokens.Spacing.md)

                    Divider()
                        .overlay(LogTokens.Colors.borderDefault)
                        .padding(.bottom, LogTokens.Spacing.xs)

                    if content != nil {
                        switch mode {
                        case .raw:
                            rawChunks
                        case .json:
                            jsonNodes(proxy: proxy)
                        }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(LogTokens.Spacing.md)
                    }
                }
            }
            .topBar {
                if let content {
                    contentHeader(hasJSON: !content.jsonTree.isEmpty)
                }
            }
            .onChange(of: json.currentMatchID) { id in
                guard let id, mode == .json else { return }
                scroll(proxy, to: id)
            }
            .onChange(of: raw.currentChunkIndex) { index in
                guard let index, mode == .raw else { return }
                // Waits for the rows revealed by expanding the log to be added.
                DispatchQueue.main.async { scroll(proxy, to: RawChunkID(index: index)) }
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
            raw.load(chunks: content.rawChunks, previewChunkCount: content.rawPreviewChunkCount)
            json.load(content.jsonTree)
        }
    }

    // Lazy stacks estimate the position of rows that are not laid out yet, so far away rows are
    // scrolled to a second time once they are laid out.
    private func scroll(_ proxy: ScrollViewProxy, to id: some Hashable) {
        proxy.scrollTo(id, anchor: .center)
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(id, anchor: .center) }
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
            }
            switch mode {
            case .raw:
                LogRawToolbar(viewModel: raw)
            case .json:
                LogJSONToolbar(viewModel: json)
            }
        }
        .padding(.horizontal, LogTokens.Spacing.md)
        .padding(.vertical, LogTokens.Spacing.xs)
    }

    // The raw log is shown in chunks, as text views lay out a whole paragraph at once,
    // and logs can contain very long lines, such as minified JSON responses.
    @ViewBuilder
    private var rawChunks: some View {
        let chunks = raw.chunks
        ForEach(0..<raw.visibleChunkCount, id: \.self) { index in
            rawChunkText(chunks[index])
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(LogTokens.Colors.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LogTokens.Spacing.xs)
                .background(
                    raw.currentChunkIndex == index ? LogTokens.Colors.accentPrimary.opacity(0.12) : .clear,
                    in: RoundedRectangle(cornerRadius: LogTokens.Radius.sm)
                )
                .padding(.horizontal, LogTokens.Spacing.xs)
                .id(RawChunkID(index: index))
        }
        if raw.visibleChunkCount < chunks.count {
            Text("…")
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(LogTokens.Colors.textTertiary)
                .padding(.horizontal, LogTokens.Spacing.md)
                .accessibilityLabel("Log truncated")
        }
        Color.clear
            .frame(height: LogTokens.Spacing.md)
    }

    private func rawChunkText(_ chunk: String) -> Text {
        guard !chunk.isEmpty else { return Text(" ") }
        return Text(LogHighlightedText.attributedString(chunk, highlightingAll: raw.matchedText, color: appearance.highlightColor))
    }

    @ViewBuilder
    private func jsonNodes(proxy: ScrollViewProxy) -> some View {
        let tree = json.tree
        ForEach(json.visibleIDs, id: \.self) { id in
            LogJSONNodeRow(
                node: tree.nodes[id],
                isExpanded: json.expandedIDs.contains(id),
                searchText: json.matchedText,
                isCurrentMatch: json.currentMatchID == id,
                isFocused: json.focusedID == id,
                toggle: {
                    withAnimation(.easeInOut(duration: 0.15)) { json.toggle(id) }
                    // Lazy stacks re-estimate row heights after expanding, which can shift the tapped row.
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(id, anchor: Self.scrollAnchor) }
                    }
                },
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
