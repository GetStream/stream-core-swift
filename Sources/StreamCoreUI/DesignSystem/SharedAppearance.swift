//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The design system every Stream SDK draws from: colours, layout tokens,
/// text styles and generic icons.
///
/// Each SDK exposes these through its own appearance object and adds the
/// pieces only it needs. Because every SDK defaults to ``shared``, an app
/// that runs more than one of them reskins them together:
///
/// ```swift
/// SharedAppearance.shared.colors.brand500 = .purple
/// ```
///
/// - Important: The default instance is process-wide, so an override made
/// through one SDK is visible to the others. To keep them apart, build a
/// separate instance and hand it to the SDK's appearance object.
///
/// Tokens derive lazily, so apply overrides before the first read.
public final class SharedAppearance: @unchecked Sendable {
    /// The instance every Stream SDK uses unless it is given another one.
    public static let shared = SharedAppearance()

    public let colors: SharedColorPalette
    public let tokens: SharedDesignSystemTokens
    public let fonts: SharedFonts
    public let images: SharedImages

    public init(
        colors: SharedColorPalette = .init(),
        tokens: SharedDesignSystemTokens = .init(),
        fonts: SharedFonts = .init(),
        images: SharedImages = .init()
    ) {
        self.colors = colors
        self.tokens = tokens
        self.fonts = fonts
        self.images = images
    }
}
