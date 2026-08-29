//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// The text styles every Stream SDK draws from.
///
/// The same fourteen styles are vended twice, once as `UIFont` and once as
/// SwiftUI `Font`, because Stream's SDKs are split across both frameworks.
/// The two faces are independent: overriding `uiKit.body` leaves
/// `swiftUI.body` untouched, so an app that renders in both frameworks
/// should set the style it actually uses, or both.
public final class SharedFonts: @unchecked Sendable {
    /// Process-wide default, used when an SDK does not pass its own fonts.
    public static let shared = SharedFonts()

    public let uiKit: UIKitFace
    public let swiftUI: SwiftUIFace

    public init(
        uiKit: UIKitFace = .init(),
        swiftUI: SwiftUIFace = .init()
    ) {
        self.uiKit = uiKit
        self.swiftUI = swiftUI
    }

    // MARK: - UIKit

    /// The `UIFont` face of the shared text styles.
    public final class UIKitFace: @unchecked Sendable {
        public var caption1 = UIFont.preferredFont(forTextStyle: .caption1)
        public var footnote = UIFont.preferredFont(forTextStyle: .footnote)
        public var footnoteBold = UIFont.preferredFont(forTextStyle: .footnote).bold
        public var subheadline = UIFont.preferredFont(forTextStyle: .subheadline)
        public var subheadlineBold = UIFont.preferredFont(forTextStyle: .subheadline).bold
        public var body = UIFont.preferredFont(forTextStyle: .body)
        public var bodyBold = UIFont.preferredFont(forTextStyle: .body).bold
        public var bodyItalic = UIFont.preferredFont(forTextStyle: .body).italic
        public var headline = UIFont.preferredFont(forTextStyle: .headline)
        public var headlineBold = UIFont.preferredFont(forTextStyle: .headline).bold
        public var title = UIFont.preferredFont(forTextStyle: .title1)
        public var title2 = UIFont.preferredFont(forTextStyle: .title2)
        /// - Note: Bold, unlike its SwiftUI counterpart. The two faces
        /// disagree here because each preserves what its SDK rendered
        /// before the styles were shared.
        public var title3 = UIFont.preferredFont(forTextStyle: .title3).bold
        /// Renders emojis as "Jumbomoji".
        public var emoji = UIFont.preferredFont(forTextStyle: .body).withSize(50)

        public init() { /* Public init. */ }
    }

    // MARK: - SwiftUI

    /// The SwiftUI `Font` face of the shared text styles.
    public final class SwiftUIFace: @unchecked Sendable {
        public var caption1 = Font.caption
        public var footnote = Font.footnote
        public var footnoteBold = Font.footnote.bold()
        public var subheadline = Font.subheadline
        public var subheadlineBold = Font.subheadline.bold()
        public var body = Font.body
        public var bodyBold = Font.body.bold()
        public var bodyItalic = Font.body.italic()
        public var headline = Font.headline
        public var headlineBold = Font.headline.bold()
        public var title = Font.title
        public var title2 = title2Font
        public var title3 = title3Font
        /// Renders emojis as "Jumbomoji".
        public var emoji = Font.system(size: 50)

        public init() { /* Public init. */ }

        private static var title2Font: Font {
            if #available(iOS 14.0, *) {
                return .title2
            } else {
                return .title
            }
        }

        private static var title3Font: Font {
            if #available(iOS 14.0, *) {
                return .title3
            } else {
                return .headline
            }
        }
    }
}
