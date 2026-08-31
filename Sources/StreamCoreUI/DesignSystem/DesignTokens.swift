//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// Shared design tokens every Stream SDK draws from, grouped by kind.
///
/// Pass the same instance into each product appearance so Chat and Video
/// reskin together. Colour and layout live on separate properties so a
/// later fonts group can be added the same way.
///
/// ```swift
/// let tokens = DesignTokens()
/// tokens.colors.accentPrimary = .red
/// let videoAppearance = VideoAppearance(tokens: tokens)
/// let chatAppearance = ChatAppearance(tokens: tokens)
/// ```
///
/// - Important: Start by adjusting the `brand` and `chrome` ramps on
/// ``DesignTokens/Colors``. Most semantic colour tokens derive from them.
/// Tokens derive lazily, so override the ramps before the first read.
public final class DesignTokens {
    /// Shared colour tokens.
    public var colors: Colors
    /// Shared layout tokens.
    public var layout: Layout

    public init(
        colors: Colors = Colors(),
        layout: Layout = Layout()
    ) {
        self.colors = colors
        self.layout = layout
    }
}
