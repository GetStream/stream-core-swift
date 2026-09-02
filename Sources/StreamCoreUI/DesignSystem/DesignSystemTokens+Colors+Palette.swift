//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// Brand and chrome scales semantic color tokens derive from.
///
/// Override these before the first read of a derived token. A handful
/// of palette changes reskins every SDK that shares this instance.
extension DesignSystemTokens.Colors {
    public final class Palette {
        // MARK: - Brand

        public lazy var brand50: UIColor = UIColor(light: .blue50, dark: .blue900)
        public lazy var brand100: UIColor = UIColor(light: .blue100, dark: .blue800)
        public lazy var brand150: UIColor = UIColor(light: .blue150, dark: .blue700)
        public lazy var brand200: UIColor = UIColor(light: .blue200, dark: .blue600)
        public lazy var brand300: UIColor = UIColor(light: .blue300, dark: .blue500)
        public lazy var brand400: UIColor = .blue400
        public lazy var brand500: UIColor = UIColor(light: .blue500, dark: .blue300)
        public lazy var brand600: UIColor = UIColor(light: .blue600, dark: .blue200)
        public lazy var brand700: UIColor = UIColor(light: .blue700, dark: .blue150)
        public lazy var brand800: UIColor = UIColor(light: .blue800, dark: .blue100)
        public lazy var brand900: UIColor = UIColor(light: .blue900, dark: .blue50)

        // MARK: - Chrome

        public lazy var chrome0: UIColor = UIColor(light: .baseWhite, dark: .baseBlack)
        public lazy var chrome50: UIColor = UIColor(light: .slate50, dark: .neutral900)
        public lazy var chrome100: UIColor = UIColor(light: .slate100, dark: .neutral800)
        public lazy var chrome150: UIColor = UIColor(light: .slate150, dark: .neutral700)
        public lazy var chrome200: UIColor = UIColor(light: .slate200, dark: .neutral600)
        public lazy var chrome300: UIColor = UIColor(light: .slate300, dark: .neutral500)
        public lazy var chrome400: UIColor = UIColor(light: .slate400, dark: .neutral400)
        public lazy var chrome500: UIColor = UIColor(light: .slate500, dark: .neutral300)
        public lazy var chrome600: UIColor = UIColor(light: .slate600, dark: .neutral200)
        public lazy var chrome700: UIColor = UIColor(light: .slate700, dark: .neutral150)
        public lazy var chrome800: UIColor = UIColor(light: .slate800, dark: .neutral100)
        public lazy var chrome900: UIColor = UIColor(light: .slate900, dark: .neutral50)
        public lazy var chrome1000: UIColor = UIColor(light: .baseBlack, dark: .baseWhite)

        public init() { /* Public init. */ }
    }
}
