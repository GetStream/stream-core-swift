//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Shared typography tokens every Stream SDK draws from.
///
/// Core exposes SwiftUI ``Font`` values. UIKit ``UIFont`` faces stay on
/// product UIKit SDKs (for example StreamChatUI).
extension DesignSystemTokens {
    public final class Fonts {
        public var caption1: Font = .caption
        public var footnoteBold: Font = .footnote.bold()
        public var footnote: Font = .footnote
        public var subheadline: Font = .subheadline
        public var subheadlineBold: Font = .subheadline.bold()
        public var body: Font = .body
        public var bodyBold: Font = .body.bold()
        public var bodyItalic: Font = .body.italic()
        public var headline: Font = .headline
        public var headlineBold: Font = .headline.bold()
        public var title: Font = .title

        private var _title2: Font?
        private var _title3: Font?

        public var title2: Font {
            get {
                if let value = _title2 { return value }
                if #available(iOS 14.0, *) { return .title2 }
                return .title
            }
            set { _title2 = newValue }
        }

        public var title3: Font {
            get {
                if let value = _title3 { return value }
                if #available(iOS 14.0, *) { return .title3 }
                return .title
            }
            set { _title3 = newValue }
        }

        /// A font used to render emojis as "Jumbomoji".
        public var emoji: Font = .system(size: 50)

        public init() {
            // Public init.
        }
    }
}
