//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// Trait helpers used to build the UIKit face of `SharedFonts`.
///
/// Deliberately internal: SDKs that already vend equivalent helpers would
/// otherwise see two identical members on `UIFont` once they link CoreUI.
extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }

    var bold: UIFont { withTraits(.traitBold) }

    var italic: UIFont { withTraits(.traitItalic) }
}
