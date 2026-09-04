//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// Shared design tokens every Stream SDK draws from, grouped by kind.
///
/// Pass the same instance into each product appearance so Chat and Video
/// reskin together. Color, layout, and fonts live on separate properties so
/// each group can evolve independently.
///
/// ```swift
/// let tokens = DesignSystemTokens()
/// tokens.colors.accentPrimary = .red
/// let videoAppearance = VideoAppearance(tokens: tokens)
/// let chatAppearance = ChatAppearance(tokens: tokens)
/// ```
///
/// - Important: Start by adjusting ``DesignSystemTokens/Colors/palette``.
/// Most semantic color tokens derive from its brand and chrome scales.
/// Tokens derive lazily, so override the palette before the first read.
/// Typography uses SwiftUI ``Font``; UIKit ``UIFont`` faces stay on product
/// UIKit SDKs.
public final class DesignSystemTokens {
    /// Shared color tokens.
    public var colors: Colors
    /// Shared layout tokens.
    public var layout: Layout
    /// Shared typography tokens.
    public var fonts: Fonts

    public init(
        colors: Colors = Colors(),
        layout: Layout = Layout(),
        fonts: Fonts = Fonts()
    ) {
        self.colors = colors
        self.layout = layout
        self.fonts = fonts
    }
}
