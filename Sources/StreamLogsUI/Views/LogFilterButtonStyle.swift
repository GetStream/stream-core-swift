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
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, LogTokens.Spacing.sm)
            .padding(.vertical, LogTokens.Spacing.xs - 2)
            .background(background, in: Capsule())
            .overlay {
                if !isSelected {
                    Capsule().strokeBorder(LogTokens.Colors.borderDefault)
                }
            }
            .foregroundColor(foreground)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var foreground: Color {
        if let tint {
            return tint
        }
        return isSelected ? LogTokens.Colors.textOnAccent : LogTokens.Colors.textPrimary
    }

    private var background: Color {
        if let tint {
            return tint.opacity(0.15)
        }
        return isSelected ? LogTokens.Colors.accentPrimary : LogTokens.Colors.backgroundSurfaceCard
    }
}
