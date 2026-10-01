//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogLevelPickerView: View {
    let levels: [LogEntry.Level]
    @Binding var minimumLevel: LogEntry.Level?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LogPickerContainer(title: "Select Level") {
            Section {
                option(title: "All Levels", level: nil)
                ForEach(levels, id: \.self) { level in
                    option(title: level.name, level: level)
                }
            } header: {
                Text("Minimum Level")
            } footer: {
                Text("Shows logs of the selected level and above.")
            }
        }
    }

    private func option(title: String, level: LogEntry.Level?) -> some View {
        Button {
            minimumLevel = level
            dismiss()
        } label: {
            LogPickerRow(title: title, isSelected: minimumLevel == level)
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

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
                .fontWeight(isSelected ? .semibold : .regular)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
