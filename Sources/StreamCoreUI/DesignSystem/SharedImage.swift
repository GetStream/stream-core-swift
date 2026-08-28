//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

/// A single icon of the shared set, vended for both UIKit and SwiftUI.
///
/// The two faces are built independently rather than bridged, because a
/// symbol that reaches SwiftUI through `Image(uiImage:)` stops scaling with
/// the surrounding font and needs its rendering mode forced before it tints
/// as a template. Building each face from the symbol name keeps both sides
/// behaving the way they would if the SDK had written them by hand.
///
/// Overriding one face leaves the other alone, so an app that renders in
/// both frameworks should set the face it actually draws, or both.
public struct SharedImage: @unchecked Sendable {
    /// The icon as drawn by UIKit.
    public var uiImage: UIImage
    /// The icon as drawn by SwiftUI.
    public var image: Image

    public init(uiImage: UIImage, image: Image) {
        self.uiImage = uiImage
        self.image = image
    }

    /// Wraps a `UIImage`, deriving the SwiftUI face from it.
    public init(uiImage: UIImage) {
        self.init(uiImage: uiImage, image: Image(uiImage: uiImage))
    }

    /// Builds both faces from an SF Symbol name.
    ///
    /// - Parameter name: A symbol available on the SDK's minimum
    /// deployment target. Missing symbols resolve to an empty image and are
    /// logged rather than crashing.
    public static func system(_ name: String) -> SharedImage {
        guard let uiImage = UIImage(systemName: name) else {
            log.error("SF Symbol '\(name)' is unavailable on this OS version.")
            return SharedImage(uiImage: UIImage(), image: Image(systemName: name))
        }
        return SharedImage(uiImage: uiImage, image: Image(systemName: name))
    }
}
