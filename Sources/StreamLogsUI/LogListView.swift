//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// A debugging view that lists the log entries of a ``LogRecorder``.
///
/// Entries can be searched, filtered by level and subsystem, and copied.
///
/// Place the view inside a `NavigationStack`, which it uses to show the log settings.
@available(iOS 16.0, *)
public struct LogListView: View {
    @StateObject private var viewModel: LogListViewModel
    @ObservedObject private var settings: LogSettings
    @State private var isShowingLevelPicker = false
    @State private var isShowingSubsystemPicker = false
    @State private var isConfirmingClear = false
    @Environment(\.logViewerAppearance) private var appearance

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
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search logs"
            )
            .toolbar {
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

                    NavigationLink {
                        LogSettingsView(settings: settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Log settings")
                }
            }
            .sheet(isPresented: $isShowingLevelPicker) {
                LogLevelPickerView(
                    levels: Set(settings.availableLevels).union(viewModel.availableLevels).sorted(),
                    selectedLevels: $viewModel.selectedLevels
                )
                .logViewerAppearance(appearance)
            }
            .sheet(isPresented: $isShowingSubsystemPicker) {
                LogSubsystemPickerView(
                    subsystems: Set(settings.availableSubsystems).union(viewModel.availableSubsystems).sorted(),
                    selectedSubsystems: $viewModel.selectedSubsystems
                )
            }
        }
    }

    private var filterBar: some View {
        VStack(spacing: 0) {
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

                if settings.enabledDestinations.isEmpty {
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
        VStack(spacing: 0) {
            LogRowView(entry: entry, searchText: viewModel.searchText)
                .padding(.horizontal, LogTokens.Spacing.md)
                .padding(.vertical, LogTokens.Spacing.sm)
            Divider()
                .overlay(LogTokens.Colors.borderDefault.opacity(0.6))
                .padding(.leading, LogTokens.Spacing.md)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                UIPasteboard.general.string = entry.rawText
            } label: {
                Label("Copy Log", systemImage: "doc.on.doc")
            }

            Button(role: .destructive) {
                viewModel.removeEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
