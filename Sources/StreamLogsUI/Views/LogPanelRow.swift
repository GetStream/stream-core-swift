//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

enum LogPanelRowPosition {
    case top
    case middle
    case bottom
}

@available(iOS 16.0, *)
extension View {
    // Lazily loaded rows cannot share a container, so each row draws its part of the panel.
    func logPanelRow(_ position: LogPanelRowPosition = .middle) -> some View {
        background(LogTokens.Colors.backgroundSurfaceCard, in: LogPanelRowShape(position: position))
            .padding(.horizontal, LogTokens.Spacing.md)
    }
}

private struct LogPanelRowShape: Shape {
    let position: LogPanelRowPosition

    func path(in rect: CGRect) -> Path {
        let corners: UIRectCorner = switch position {
        case .top: [.topLeft, .topRight]
        case .middle: []
        case .bottom: [.bottomLeft, .bottomRight]
        }
        let radius = CGSize(width: LogTokens.Radius.lg, height: LogTokens.Radius.lg)
        return Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: radius).cgPath)
    }
}
