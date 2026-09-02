//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// An elevation token, expressed as a single drop shadow.
public struct BoxShadow: @unchecked Sendable {
    public let x: CGFloat
    public let y: CGFloat
    public let blur: CGFloat
    public let spread: CGFloat
    public let color: UIColor

    public init(
        x: CGFloat,
        y: CGFloat,
        blur: CGFloat,
        spread: CGFloat,
        color: UIColor
    ) {
        self.x = x
        self.y = y
        self.blur = blur
        self.spread = spread
        self.color = color
    }
}
