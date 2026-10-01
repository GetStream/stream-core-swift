//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A form to enable, disable and configure the logger at runtime.
@available(iOS 16.0, *)
public struct LogSettingsView: View {
    @ObservedObject private var settings: LogSettings

    /// Creates a form that edits the given settings.
    public init(settings: LogSettings = .shared) {
        self.settings = settings
    }

    public var body: some View {
        Form {
            Section {
                Toggle("Logging", isOn: $settings.isEnabled)
            } footer: {
                Text("When disabled, logs are neither printed nor recorded.")
            }

            Section {
                Picker("Level", selection: $settings.level) {
                    ForEach(settings.availableLevels, id: \.self) { level in
                        Text(level.name).tag(level)
                    }
                }
            } footer: {
                Text("Logs below this level are ignored.")
            }
            .disabled(!settings.isEnabled)

            if !settings.availableSubsystems.isEmpty {
                subsystemsSection
                    .disabled(!settings.isEnabled)
            }

            Section {
                Button("Reset to Defaults", role: .destructive) {
                    settings.reset()
                }
            }
        }
        .navigationTitle("Log Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subsystemsSection: some View {
        Section("Subsystems") {
            let areAllEnabled = settings.enabledSubsystems.count == settings.availableSubsystems.count
            Button(areAllEnabled ? "Disable All" : "Enable All") {
                settings.disabledSubsystems = areAllEnabled ? Set(settings.availableSubsystems) : []
            }

            ForEach(settings.availableSubsystems, id: \.self) { subsystem in
                Toggle(subsystem, isOn: Binding(
                    get: { !settings.disabledSubsystems.contains(subsystem) },
                    set: { settings.setSubsystem(subsystem, isEnabled: $0) }
                ))
            }
        }
    }
}
