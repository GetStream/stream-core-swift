//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

// Values of the Stream design system tokens (StreamCoreUI's `DesignSystemTokens`),
// copied because StreamLogsUI has no dependencies.
@usableFromInline
enum LogTokens {
    enum UIColors {
        static let accentPrimary = UIColor(light: 0x005fff, dark: 0x4586ff)
    }

    @usableFromInline
    enum Colors {
        static let accentPrimary = Color(UIColors.accentPrimary)
        static let accentSuccess = Color(light: 0x00a46e, dark: 0x00c384)
        // Darker than the `accentWarning` token, which is meant for backgrounds and is hard to read as text.
        static let accentWarning = Color(light: 0xf26d10, dark: 0xfa922b)
        static let accentError = Color(light: 0xd90d10, dark: 0xfc526a)
        static let accentCritical = Color(light: 0xb3093c, dark: 0xfe87a1)
        @usableFromInline static let accentNeutral = Color(light: 0x687385, dark: 0xababab)
        static let accentInfo = Color(light: 0x1e9ea9, dark: 0x45bcc7)
        static let accentTrace = Color(light: 0x87909f, dark: 0x8f8f8f)

        static let textPrimary = Color(light: 0x1a1b25, dark: 0xf8f8f8)
        static let textSecondary = Color(light: 0x414552, dark: 0xd8d8d8)
        static let textTertiary = Color(light: 0x687385, dark: 0xababab)
        static let textOnAccent = Color(light: 0xffffff, dark: 0x000000)

        static let backgroundSurfaceCard = Color(light: 0xf6f8fa, dark: 0x323232)
        static let backgroundSurfaceDefault = Color(light: 0xebeef1, dark: 0x323232)
        static let borderDefault = Color(light: 0xd5dbe1, dark: 0x464646)
        @usableFromInline static let highlight = Color(light: 0xfcd579, dark: 0xc84801).opacity(0.45)
    }

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
    }
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor(light: light, dark: dark))
    }
}

extension UIColor {
    convenience init(light: UInt32, dark: UInt32) {
        self.init { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }

    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xff) / 255,
            green: CGFloat((rgb >> 8) & 0xff) / 255,
            blue: CGFloat(rgb & 0xff) / 255,
            alpha: 1
        )
    }
}
