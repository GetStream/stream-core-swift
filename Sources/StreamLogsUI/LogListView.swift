//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// A debugging view that lists the log entries recorded in a ``LogStore``.
///
/// Entries can be searched, filtered by level and subsystem, inspected, and copied.
///
/// Place the view inside a `NavigationStack`, which it uses to show entry details and the log settings.
@available(iOS 16.0, *)
public struct LogListView: View {
    @StateObject private var viewModel: LogListViewModel
    @ObservedObject private var settings: LogSettings
    @State private var isShowingLevelPicker = false
    @State private var isShowingSubsystemPicker = false
    @Environment(\.logViewerAppearance) private var appearance

    private let topID = "top"

    /// Creates a view that lists the entries of the given store, with access to the given logger settings.
    ///
    /// - Parameter filter: The filter applied when the view appears. It can then be changed from the view.
    public init(store: any LogStore = InMemoryLogStore.shared, settings: LogSettings = .shared, filter: LogFilter = LogFilter()) {
        _viewModel = StateObject(wrappedValue: LogListViewModel(store: store, filter: filter))
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
            .navigationDestination(for: LogEntry.self) { entry in
                LogDetailView(entry: entry)
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search logs"
            )
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        viewModel.isRecording.toggle()
                    } label: {
                        Image(systemName: viewModel.isRecording ? "record.circle.fill" : "record.circle")
                            .foregroundColor(viewModel.isRecording ? .red : .gray)
                    }
                    .accessibilityLabel(viewModel.isRecording ? "Stop recording" : "Start recording")

                    Button {
                        viewModel.removeAll()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Clear logs")

                    NavigationLink {
                        LogSettingsView(settings: settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Log settings")
                }
            }
            .sheet(isPresented: $isShowingLevelPicker) {
                LogLevelPickerView(levels: viewModel.availableLevels, minimumLevel: $viewModel.minimumLevel)
                    .logViewerAppearance(appearance)
            }
            .sheet(isPresented: $isShowingSubsystemPicker) {
                LogSubsystemPickerView(
                    subsystems: viewModel.availableSubsystems,
                    selectedSubsystems: $viewModel.selectedSubsystems
                )
            }
        }
    }

    private var filterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        isShowingLevelPicker = true
                    } label: {
                        filterLabel(viewModel.minimumLevel.map { "\($0.name)+" } ?? "All Levels", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(LogFilterButtonStyle(
                        isSelected: viewModel.minimumLevel != nil,
                        tint: viewModel.minimumLevel.map { appearance.levelStyle($0).color }
                    ))
                    .accessibilityLabel(viewModel.minimumLevel.map { "Level \($0.name) and above" } ?? "All levels")

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
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            if viewModel.isFiltering {
                let count = viewModel.filteredEntries.count
                Text("\(count) result\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }
        }
    }

    private func newEntriesButton(action: @escaping () -> Void) -> some View {
        let count = viewModel.newEntriesCount
        let title = "\(count) new log\(count == 1 ? "" : "s")"
        return Button(action: action) {
            Label(title, systemImage: "arrow.up")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.accentColor))
                .shadow(radius: 4)
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
            VStack(spacing: 16) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Text(viewModel.isFiltering ? "No matching logs found" : "No logs available")
                    .font(.headline)
                    .foregroundColor(.secondary)

                if settings.enabledDestinations.isEmpty {
                    Text("All destinations are disabled in the log settings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else if viewModel.isFiltering {
                    Text("Try adjusting your search terms or filters")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
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
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                Divider()
                    .padding(.leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                UIPasteboard.general.string = entry.message
            } label: {
                Label("Copy Message", systemImage: "doc.on.doc")
            }

            Button(role: .destructive) {
                viewModel.removeEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func topBar(@ViewBuilder _ content: () -> some View) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .top, spacing: 0, content: content)
        } else {
            safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    content()
                    Divider()
                }
                .background(.bar)
            }
        }
    }
}
