//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogLevelPickerView: View {
    let levels: [LogEntry.Level]
    @Binding var selectedLevels: Set<LogEntry.Level>
    @Environment(\.logViewerAppearance) private var appearance

    var body: some View {
        LogPickerContainer(title: "Select Levels") {
            Section {
                Button {
                    selectedLevels.removeAll()
                } label: {
                    LogPickerRow(title: "All Levels", isSelected: selectedLevels.isEmpty)
                }
                ForEach(levels, id: \.self) { level in
                    Button {
                        if selectedLevels.contains(level) {
                            selectedLevels.remove(level)
                        } else {
                            selectedLevels.insert(level)
                        }
                    } label: {
                        LogPickerRow(title: level.name, isSelected: selectedLevels.contains(level), style: appearance.levelStyle(level))
                    }
                }
            } header: {
                Text("Levels")
            } footer: {
                Text("Shows only logs with the selected levels.")
            }
        }
    }
}

@available(iOS 16.0, *)
struct LogSubsystemPickerView: View {
    let subsystems: [String]
    @Binding var selectedSubsystems: Set<String>

    var body: some View {
        LogPickerContainer(title: "Select Subsystems") {
            Section("Subsystems") {
                if subsystems.isEmpty {
                    Text("No subsystems recorded yet")
                        .foregroundColor(.secondary)
                }
                ForEach(subsystems, id: \.self) { subsystem in
                    Button {
                        if selectedSubsystems.contains(subsystem) {
                            selectedSubsystems.remove(subsystem)
                        } else {
                            selectedSubsystems.insert(subsystem)
                        }
                    } label: {
                        LogPickerRow(title: subsystem, isSelected: selectedSubsystems.contains(subsystem))
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
private struct LogPickerContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List { content }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

@available(iOS 16.0, *)
private struct LogPickerRow: View {
    let title: String
    let isSelected: Bool
    var style: LogViewerAppearance.LevelStyle?

    var body: some View {
        HStack {
            if let style {
                Image(systemName: style.iconName)
                    .foregroundColor(style.color)
                    .accessibilityHidden(true)
            }
            Text(title)
                .foregroundColor(.primary)
                .fontWeight(isSelected ? .semibold : .regular)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(LogTokens.Colors.accentPrimary)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
