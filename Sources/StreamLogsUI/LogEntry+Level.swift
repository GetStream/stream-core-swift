//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension LogEntry.Level {
    var displayName: String {
        switch self {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warning: "WARNING"
        case .error: "ERROR"
        }
    }

    var color: Color {
        switch self {
        case .debug: .purple
        case .info: .blue
        case .warning: .orange
        case .error: .red
        }
    }

    var iconName: String {
        switch self {
        case .debug: "ant.circle"
        case .info: "info.circle"
        case .warning: "exclamationmark.triangle"
        case .error: "xmark.circle"
        }
    }
}
