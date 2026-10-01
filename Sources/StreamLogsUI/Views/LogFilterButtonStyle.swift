//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogFilterButtonStyle: ButtonStyle {
    var isSelected: Bool
    var tint: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background)
            .foregroundColor(tint ?? (isSelected ? .white : .primary))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var background: Color {
        if let tint {
            return tint.opacity(0.2)
        }
        return isSelected ? .accentColor : Color(.systemGray5)
    }
}
