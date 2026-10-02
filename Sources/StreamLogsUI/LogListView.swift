//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// A debugging view that lists the log entries of a ``LogRecorder``.
///
/// Entries can be searched, filtered by level and subsystem, inspected, copied, and exported as a ``LogSession`` file.
/// Exported files can be imported back, and are displayed apart from the recorded entries.
///
/// Place the view inside a `NavigationStack`, which it uses to show entry details and the log settings.
@available(iOS 16.0, *)
public struct LogListView: View {
    @StateObject private var viewModel: LogListViewModel
    @ObservedObject private var settings: LogSettings
    @State private var isShowingLevelPicker = false
    @State private var isShowingSubsystemPicker = false
    @State private var isConfirmingClear = false
    @State private var isImporting = false
    @State private var importedSession: ImportedLogSession?
    @State private var importErrorMessage: String?
    @Environment(\.logViewerAppearance) private var appearance
    @Environment(\.dismiss) private var dismiss

    private let recorder: (any LogRecorder)?
    private let session: LogSession?
    private let topID = "top"

    /// Creates a view that lists the entries of the given recorder, with access to the given logger settings.
    ///
    /// - Parameter filter: The filter applied when the view appears. It can then be changed from the view.
    public init(
        recorder: any LogRecorder = InMemoryLogRecorder.shared,
        settings: LogSettings = .shared,
        filter: LogFilter = LogFilter()
    ) {
        _viewModel = StateObject(wrappedValue: LogListViewModel(recorder: recorder, filter: filter))
        self.settings = settings
        self.recorder = recorder
        session = nil
    }

    // Lists the entries of an imported session, which can't be recorded to or changed.
    init(session: LogSession) {
        _viewModel = StateObject(wrappedValue: LogListViewModel(recorder: InMemoryLogRecorder(session: session)))
        settings = .shared
        recorder = nil
        self.session = session
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Color.clear
                        .frame(height: 1)
                        .id(topID)
                        .onAppear { viewModel.isFollowingNewEntries = true }
                        .onDisappear { viewModel.isFollowingNewEntries = false }

                    content
                }
            }
            .topBar { filterBar }
            .overlay(alignment: .bottom) {
                if viewModel.newEntriesCount > 0 {
                    newEntriesButton {
                        viewModel.showNewEntries()
                        withAnimation {
                            proxy.scrollTo(topID, anchor: .top)
                        }
                    }
                }
            }
            .onAppear { viewModel.refreshRecordingState() }
            .navigationTitle(session == nil ? "Logs" : "Imported Logs")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: LogEntry.self) { entry in
                LogDetailView(entry: entry)
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search logs"
            )
            .toolbar {
                if session != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                } else {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            viewModel.isRecording.toggle()
                        } label: {
                            Image(systemName: viewModel.isRecording ? "record.circle.fill" : "record.circle")
                                .foregroundColor(viewModel.isRecording ? LogTokens.Colors.accentError : LogTokens.Colors.textTertiary)
                        }
                        .accessibilityLabel(viewModel.isRecording ? "Stop recording" : "Start recording")

                        Button {
                            isConfirmingClear = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Clear logs")
                        .confirmationDialog("Delete All Logs?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
                            Button("Delete All Logs", role: .destructive) {
                                viewModel.removeAll()
                            }
                        } message: {
                            Text("All recorded logs will be deleted. This can't be undone.")
                        }

                        sessionMenu

                        NavigationLink {
                            LogSettingsView(settings: settings)
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Log settings")
                    }
                }
            }
            .sheet(isPresented: $isShowingLevelPicker) {
                LogLevelPickerView(
                    levels: session == nil
                        ? Set(settings.availableLevels).union(viewModel.availableLevels).sorted()
                        : viewModel.availableLevels,
                    selectedLevels: $viewModel.selectedLevels
                )
                .logViewerAppearance(appearance)
            }
            .sheet(isPresented: $isShowingSubsystemPicker) {
                LogSubsystemPickerView(
                    subsystems: session == nil
                        ? Set(settings.availableSubsystems).union(viewModel.availableSubsystems).sorted()
                        : viewModel.availableSubsystems,
                    selectedSubsystems: $viewModel.selectedSubsystems
                )
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                importSession(from: result)
            }
            .sheet(item: $importedSession) { imported in
                NavigationStack {
                    LogListView(session: imported.session)
                }
                .logViewerAppearance(appearance)
            }
            .alert(
                "Unable to Import Logs",
                isPresented: Binding(
                    get: { importErrorMessage != nil },
                    set: { if !$0 { importErrorMessage = nil } }
                ),
                actions: {},
                message: { Text(importErrorMessage ?? "") }
            )
        }
    }

    private var sessionMenu: some View {
        Menu {
            if let recorder {
                ShareLink(
                    item: LogSessionFile { recorder.entries },
                    preview: SharePreview("Logs")
                ) {
                    Label("Export All Logs", systemImage: "square.and.arrow.up")
                }
            }

            if viewModel.isFiltering {
                let entries = viewModel.filteredEntries
                ShareLink(
                    item: LogSessionFile { entries.reversed() },
                    preview: SharePreview("Filtered Logs")
                ) {
                    Label("Export Filtered Logs", systemImage: "line.3.horizontal.decrease.circle")
                }
            }

            Divider()

            Button {
                isImporting = true
            } label: {
                Label("Import Logs…", systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Export or import logs")
    }

    private func importSession(from result: Result<URL, Error>) {
        Task {
            do {
                let url = try result.get()
                let session = try await Task.detached(priority: .userInitiated) {
                    try LogSession.read(from: url)
                }.value
                importedSession = ImportedLogSession(session: session)
            } catch {
                importErrorMessage = "The file is not a valid logs file.\n\(error.localizedDescription)"
            }
        }
    }

    private var filterBar: some View {
        VStack(spacing: 0) {
            if let session {
                sessionInfo(session)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LogTokens.Spacing.xs) {
                    Button {
                        isShowingLevelPicker = true
                    } label: {
                        filterLabel(levelsTitle, systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(LogFilterButtonStyle(
                        isSelected: !viewModel.selectedLevels.isEmpty,
                        tint: viewModel.selectedLevels.count == 1 ? viewModel.selectedLevels.first.map { appearance.levelStyle($0).color } : nil
                    ))
                    .accessibilityLabel(viewModel.selectedLevels.isEmpty ? "All levels" : "Levels \(levelsTitle)")

                    Button {
                        isShowingSubsystemPicker = true
                    } label: {
                        filterLabel("Subsystems", systemImage: "gearshape.2")
                    }
                    .buttonStyle(LogFilterButtonStyle(isSelected: !viewModel.selectedSubsystems.isEmpty))

                    ForEach(viewModel.selectedSubsystems.sorted(), id: \.self) { subsystem in
                        Button {
                            viewModel.selectedSubsystems.remove(subsystem)
                        } label: {
                            HStack(spacing: 4) {
                                Text(subsystem)
                                Image(systemName: "xmark")
                                    .font(.caption2)
                            }
                        }
                        .buttonStyle(LogFilterButtonStyle(isSelected: true))
                        .accessibilityLabel("Remove \(subsystem) filter")
                    }
                }
                .padding(.horizontal, LogTokens.Spacing.md)
            }
            .padding(.vertical, LogTokens.Spacing.xs)

            if viewModel.isFiltering {
                let count = viewModel.filteredEntries.count
                Text("\(count) result\(count == 1 ? "" : "s")")
                    .font(.caption.weight(.medium))
                    .foregroundColor(LogTokens.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LogTokens.Spacing.md)
                    .padding(.bottom, LogTokens.Spacing.xxs)
            }
        }
    }

    private func sessionInfo(_ session: LogSession) -> some View {
        VStack(alignment: .leading, spacing: LogTokens.Spacing.xxxs) {
            if !session.sourceDescription.isEmpty {
                Text(session.sourceDescription)
                    .font(.caption.weight(.medium))
                    .foregroundColor(LogTokens.Colors.textSecondary)
            }
            Text("Exported \(session.exportDate.formatted(date: .abbreviated, time: .standard))")
                .font(.caption)
                .foregroundColor(LogTokens.Colors.textTertiary)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LogTokens.Spacing.md)
        .padding(.top, LogTokens.Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    private var levelsTitle: String {
        let levels = viewModel.selectedLevels.sorted()
        switch levels.count {
        case 0: return "All Levels"
        case 1, 2: return levels.map(\.name).joined(separator: ", ")
        default: return "\(levels.count) Levels"
        }
    }

    private func newEntriesButton(action: @escaping () -> Void) -> some View {
        let count = viewModel.newEntriesCount
        let title = "\(count) new log\(count == 1 ? "" : "s")"
        return Button(action: action) {
            Label(title, systemImage: "arrow.up")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(LogTokens.Colors.textOnAccent)
                .padding(.horizontal, LogTokens.Spacing.md)
                .padding(.vertical, LogTokens.Spacing.xs)
                .background(Capsule().fill(LogTokens.Colors.accentPrimary))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        }
        .padding(.bottom)
        .accessibilityLabel("Show \(title)")
    }

    private func filterLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(title)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
    }

    @ViewBuilder
    private var content: some View {
        let entries = viewModel.filteredEntries
        if entries.isEmpty {
            VStack(spacing: LogTokens.Spacing.sm) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(LogTokens.Colors.textTertiary)
                    .accessibilityHidden(true)

                Text(viewModel.isFiltering ? "No matching logs found" : "No logs available")
                    .font(.headline)
                    .foregroundColor(LogTokens.Colors.textPrimary)

                if session == nil, settings.enabledDestinations.isEmpty {
                    Text("All destinations are disabled in the log settings")
                        .font(.subheadline)
                        .foregroundColor(LogTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                } else if viewModel.isFiltering {
                    Text("Try adjusting your search terms or filters")
                        .font(.subheadline)
                        .foregroundColor(LogTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, LogTokens.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 300)
        } else {
            ForEach(entries) { entry in
                row(for: entry)
            }
        }
    }

    private func row(for entry: LogEntry) -> some View {
        NavigationLink(value: entry) {
            VStack(spacing: 0) {
                LogRowView(entry: entry, searchText: viewModel.searchText)
                    .padding(.horizontal, LogTokens.Spacing.md)
                    .padding(.vertical, LogTokens.Spacing.sm)
                Divider()
                    .overlay(LogTokens.Colors.borderDefault.opacity(0.6))
                    .padding(.leading, LogTokens.Spacing.md)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                UIPasteboard.general.string = entry.rawText
            } label: {
                Label("Copy Log", systemImage: "doc.on.doc")
            }

            if let curlCommand = entry.httpRequest?.curlCommand.flatMap(LogMessageParser.curlCommand(in:)) {
                Button {
                    UIPasteboard.general.string = curlCommand
                } label: {
                    Label("Copy as cURL", systemImage: "terminal")
                }
            }

            if session == nil {
                Button(role: .destructive) {
                    viewModel.removeEntry(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private struct ImportedLogSession: Identifiable {
    let id = UUID()
    let session: LogSession
}
