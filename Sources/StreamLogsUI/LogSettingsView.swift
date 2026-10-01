//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A form that lists the log destinations and configures them at runtime.
///
/// Place the view inside a `NavigationStack`, which it uses to show the settings of each destination.
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
                ForEach($settings.destinations) { $destination in
                    NavigationLink {
                        LogDestinationSettingsView(destination: $destination, settings: settings)
                    } label: {
                        row(for: destination)
                    }
                }
            } header: {
                Text("Destinations")
            } footer: {
                Text("Each destination decides which logs it receives.")
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

    private func row(for destination: LogDestinationSettings) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(destination.name)
            Text(summary(of: destination))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func summary(of destination: LogDestinationSettings) -> String {
        guard destination.isEnabled else { return "Off" }
        let enabledSubsystems = settings.enabledSubsystems(for: destination)
        let subsystems = if destination.disabledSubsystems.isEmpty {
            "all subsystems"
        } else {
            "\(enabledSubsystems.count) of \(settings.availableSubsystems.count) subsystems"
        }
        return "\(destination.level.name) and above, \(subsystems)"
    }
}
