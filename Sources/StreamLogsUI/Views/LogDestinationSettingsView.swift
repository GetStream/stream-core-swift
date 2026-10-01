//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogDestinationSettingsView: View {
    @Binding var destination: LogDestinationSettings
    @ObservedObject var settings: LogSettings

    var body: some View {
        Form {
            Section {
                Toggle("Enabled", isOn: $destination.isEnabled)
            } footer: {
                Text("When disabled, \(destination.name) receives no logs.")
            }

            Section {
                Picker("Level", selection: $destination.level) {
                    ForEach(settings.availableLevels, id: \.self) { level in
                        Text(level.name).tag(level)
                    }
                }
            } footer: {
                Text("Logs below this level are ignored.")
            }
            .disabled(!destination.isEnabled)

            if !settings.availableSubsystems.isEmpty {
                subsystemsSection
                    .disabled(!destination.isEnabled)
            }
        }
        .navigationTitle(destination.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var subsystemsSection: some View {
        Section("Subsystems") {
            let areAllEnabled = destination.disabledSubsystems.isEmpty
            Button(areAllEnabled ? "Disable All" : "Enable All") {
                destination.disabledSubsystems = areAllEnabled ? Set(settings.availableSubsystems) : []
            }

            ForEach(settings.availableSubsystems, id: \.self) { subsystem in
                Toggle(subsystem, isOn: Binding(
                    get: { !destination.disabledSubsystems.contains(subsystem) },
                    set: { isEnabled in
                        if isEnabled {
                            destination.disabledSubsystems.remove(subsystem)
                        } else {
                            destination.disabledSubsystems.insert(subsystem)
                        }
                    }
                ))
            }
        }
    }
}
