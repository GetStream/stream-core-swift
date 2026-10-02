//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

struct LogViewerFloatingButtonLayout: Equatable {
    enum Side: Equatable {
        case left
        case right
    }

    static let size: CGFloat = 56
    static let margin: CGFloat = 12
    static let stashedVisibleWidth: CGFloat = 24
    // How far the button keeps moving after it is released, relative to its velocity in points per second.
    static let projectionFactor: CGFloat = 0.2

    var side: Side = .right
    // 0 places the button at the top of the safe area, 1 at the bottom.
    var verticalPosition: CGFloat = 0.85
    var isStashed = false

    func center(in bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> CGPoint {
        let area = Self.area(in: bounds, safeAreaInsets: safeAreaInsets)
        let radius = Self.size / 2
        let y = area.minY + radius + verticalPosition * max(area.height - Self.size, 0)
        let x = switch (side, isStashed) {
        case (.left, false): area.minX + radius
        case (.right, false): area.maxX - radius
        case (.left, true): bounds.minX - radius + Self.stashedVisibleWidth
        case (.right, true): bounds.maxX + radius - Self.stashedVisibleWidth
        }
        return CGPoint(x: x, y: y)
    }

    static func released(
        at center: CGPoint,
        velocity: CGPoint,
        in bounds: CGRect,
        safeAreaInsets: UIEdgeInsets
    ) -> LogViewerFloatingButtonLayout {
        let projected = CGPoint(x: center.x + velocity.x * projectionFactor, y: center.y + velocity.y * projectionFactor)
        let side: Side = projected.x < bounds.midX ? .left : .right
        let stashThreshold = size / 4
        let isStashed = side == .left
            ? projected.x < bounds.minX + stashThreshold
            : projected.x > bounds.maxX - stashThreshold

        let area = area(in: bounds, safeAreaInsets: safeAreaInsets)
        let travel = max(area.height - size, 0)
        let verticalPosition = travel > 0 ? (projected.y - area.minY - size / 2) / travel : 0
        return LogViewerFloatingButtonLayout(
            side: side,
            verticalPosition: min(max(verticalPosition, 0), 1),
            isStashed: isStashed
        )
    }

    private static func area(in bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> CGRect {
        bounds.inset(by: safeAreaInsets).insetBy(dx: margin, dy: margin)
    }
}
