//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// This file is auto-generated. Do not edit.

import UIKit

/// Shared color tokens every Stream SDK draws from.
extension DesignSystemTokens {
    public final class Colors {
        /// Brand and chrome scales semantic tokens derive from.
        public var palette: Palette

        // MARK: - Accent

        public lazy var accentError: UIColor = UIColor(light: .red500, dark: .red400)
        public lazy var accentNeutral: UIColor = palette.chrome500
        public lazy var accentPrimary: UIColor = UIColor(light: palette.brand500, dark: palette.brand400)
        public lazy var accentSuccess: UIColor = UIColor(light: .green400, dark: .green300)
        public lazy var accentWarning: UIColor = UIColor(light: .yellow200, dark: .yellow150)

        // MARK: - Avatar

        public lazy var avatarBackgroundDefault: UIColor = palette.brand150
        public lazy var avatarBackgroundPlaceholder: UIColor = palette.chrome150
        public lazy var avatarPresenceBackgroundOffline: UIColor = accentNeutral
        public lazy var avatarPresenceBackgroundOnline: UIColor = accentSuccess
        public lazy var avatarPresenceBorder: UIColor = borderCoreOnInverse
        public lazy var avatarTextDefault: UIColor = palette.brand900
        public lazy var avatarTextPlaceholder: UIColor = palette.chrome500

        // MARK: - Background

        public lazy var backgroundCoreApp: UIColor = palette.chrome0
        public lazy var backgroundCoreElevation0: UIColor = palette.chrome0
        public lazy var backgroundCoreElevation1: UIColor = UIColor(light: palette.chrome0, dark: palette.chrome50)
        public lazy var backgroundCoreElevation2: UIColor = UIColor(light: palette.chrome0, dark: palette.chrome100)
        public lazy var backgroundCoreElevation3: UIColor = UIColor(light: palette.chrome0, dark: palette.chrome200)
        public lazy var backgroundCoreHighlight: UIColor = UIColor(light: .yellow50, dark: .yellow800)
        public lazy var backgroundCoreInverse: UIColor = palette.chrome1000
        public lazy var backgroundCoreOnAccent: UIColor = UIColor(light: palette.chrome0, dark: palette.chrome1000)
        public lazy var backgroundCoreOnElevation: UIColor = UIColor(light: palette.chrome100, dark: palette.chrome150)
        public lazy var backgroundCoreOverlayDark: UIColor = UIColor(light: UIColor(hex: 0x1a1b2540), dark: UIColor(hex: 0x00000080))
        public lazy var backgroundCoreOverlayDarkStrong: UIColor = UIColor(light: UIColor(hex: 0x1a1b25bf), dark: UIColor(hex: 0x000000bf))
        public lazy var backgroundCoreOverlayLight: UIColor = UIColor(light: UIColor(hex: 0xffffffbf), dark: UIColor(hex: 0x000000bf))
        public lazy var backgroundCoreScrim: UIColor = UIColor(light: UIColor(hex: 0x1a1b2580), dark: UIColor(hex: 0x000000bf))
        public lazy var backgroundCoreSurfaceCard: UIColor = UIColor(light: palette.chrome50, dark: palette.chrome100)
        public lazy var backgroundCoreSurfaceDefault: UIColor = palette.chrome100
        public lazy var backgroundCoreSurfaceStrong: UIColor = palette.chrome150
        public lazy var backgroundCoreSurfaceSubtle: UIColor = palette.chrome50
        public lazy var backgroundUtilityDisabled: UIColor = palette.chrome100
        public lazy var backgroundUtilityHover: UIColor = UIColor(light: UIColor(hex: 0x1a1b251a), dark: UIColor(hex: 0xffffff26))
        public lazy var backgroundUtilityPressed: UIColor = UIColor(light: UIColor(hex: 0x1a1b2526), dark: UIColor(hex: 0xffffff33))
        public lazy var backgroundUtilitySelected: UIColor = UIColor(light: UIColor(hex: 0x1a1b2533), dark: UIColor(hex: 0xffffff40))
        public lazy var backgroundUtilitySkeletonLoadingBase: UIColor = .baseTransparent0
        public lazy var backgroundUtilitySkeletonLoadingHighlight: UIColor = backgroundCoreOverlayLight

        // MARK: - Badge

        public lazy var badgeBackgroundDefault: UIColor = backgroundCoreElevation3
        public lazy var badgeBackgroundError: UIColor = accentError
        public lazy var badgeBackgroundInverse: UIColor = palette.chrome1000
        public lazy var badgeBackgroundNeutral: UIColor = accentNeutral
        public lazy var badgeBackgroundOverlay: UIColor = UIColor(hex: 0x000000bf)
        public lazy var badgeBackgroundPrimary: UIColor = accentPrimary
        public lazy var badgeBorder: UIColor = borderCoreOnInverse
        public lazy var badgeText: UIColor = textPrimary
        public lazy var badgeTextOnAccent: UIColor = textOnAccent
        public lazy var badgeTextOnInverse: UIColor = textOnInverse

        // MARK: - Border

        public lazy var borderCoreDefault: UIColor = UIColor(light: palette.chrome150, dark: palette.chrome200)
        public lazy var borderCoreOnAccent: UIColor = UIColor(light: palette.chrome0, dark: palette.chrome1000)
        public lazy var borderCoreOnElevation: UIColor = UIColor(light: palette.chrome150, dark: palette.chrome300)
        public lazy var borderCoreOnInverse: UIColor = palette.chrome0
        public lazy var borderCoreOnSurface: UIColor = palette.chrome300
        public lazy var borderCoreOpacityStrong: UIColor = UIColor(light: UIColor(hex: 0x1a1b2540), dark: UIColor(hex: 0xffffff40))
        public lazy var borderCoreOpacitySubtle: UIColor = UIColor(light: UIColor(hex: 0x1a1b251a), dark: UIColor(hex: 0xffffff33))
        public lazy var borderCoreStrong: UIColor = palette.chrome300
        public lazy var borderCoreSubtle: UIColor = palette.chrome100
        public lazy var borderUtilityActive: UIColor = accentPrimary
        public lazy var borderUtilityDisabled: UIColor = palette.chrome100
        public lazy var borderUtilityDisabledOnSurface: UIColor = palette.chrome150
        public lazy var borderUtilityError: UIColor = accentError
        public lazy var borderUtilityFocused: UIColor = palette.brand150
        public lazy var borderUtilityHover: UIColor = UIColor(light: UIColor(hex: 0x1a1b251a), dark: UIColor(hex: 0xffffff1a))
        public lazy var borderUtilityPressed: UIColor = UIColor(light: UIColor(hex: 0x1a1b2533), dark: UIColor(hex: 0xffffff33))
        public lazy var borderUtilitySelected: UIColor = UIColor(light: UIColor(hex: 0x1a1b2526), dark: UIColor(hex: 0xffffff26))
        public lazy var borderUtilitySuccess: UIColor = accentSuccess
        public lazy var borderUtilityWarning: UIColor = accentWarning

        // MARK: - Button

        public lazy var buttonDestructiveBackground: UIColor = accentError
        public lazy var buttonDestructiveBackgroundLiquidGlass: UIColor = backgroundCoreElevation0
        public lazy var buttonDestructiveBorder: UIColor = accentError
        public lazy var buttonDestructiveBorderOnDark: UIColor = textOnInverse
        public lazy var buttonDestructiveText: UIColor = accentError
        public lazy var buttonDestructiveTextOnAccent: UIColor = textOnAccent
        public lazy var buttonDestructiveTextOnDark: UIColor = textOnInverse
        public lazy var buttonPrimaryBackground: UIColor = accentPrimary
        public lazy var buttonPrimaryBackgroundLiquidGlass: UIColor = .baseTransparent0
        public lazy var buttonPrimaryBorder: UIColor = palette.brand200
        public lazy var buttonPrimaryBorderOnDark: UIColor = borderCoreOnInverse
        public lazy var buttonPrimaryText: UIColor = accentPrimary
        public lazy var buttonPrimaryTextOnAccent: UIColor = textOnAccent
        public lazy var buttonPrimaryTextOnDark: UIColor = textOnInverse
        public lazy var buttonSecondaryBackground: UIColor = backgroundCoreSurfaceDefault
        public lazy var buttonSecondaryBackgroundLiquidGlass: UIColor = backgroundCoreElevation0
        public lazy var buttonSecondaryBorder: UIColor = borderCoreDefault
        public lazy var buttonSecondaryBorderOnDark: UIColor = borderCoreOnInverse
        public lazy var buttonSecondaryText: UIColor = textPrimary
        public lazy var buttonSecondaryTextOnAccent: UIColor = textPrimary
        public lazy var buttonSecondaryTextOnDark: UIColor = textOnInverse

        // MARK: - Control

        public lazy var controlCheckboxBackground: UIColor = .baseTransparent0
        public lazy var controlCheckboxBackgroundSelected: UIColor = accentPrimary
        public lazy var controlCheckboxBorder: UIColor = borderCoreDefault
        public lazy var controlCheckboxIcon: UIColor = textOnAccent
        public lazy var controlChipBorder: UIColor = borderCoreDefault
        public lazy var controlChipText: UIColor = textPrimary
        public lazy var controlProgressBarFill: UIColor = accentNeutral
        public lazy var controlProgressBarFillAudio: UIColor = accentPrimary
        public lazy var controlProgressBarTrack: UIColor = backgroundCoreSurfaceStrong
        public lazy var controlRadioButtonBackground: UIColor = .baseTransparent0
        public lazy var controlRadioButtonBackgroundSelected: UIColor = accentPrimary
        public lazy var controlRadioButtonBorder: UIColor = borderCoreDefault
        public lazy var controlRadioButtonIndicator: UIColor = textOnAccent
        public lazy var controlRadioCheckBackground: UIColor = .baseTransparent0
        public lazy var controlRadioCheckBackgroundSelected: UIColor = accentPrimary
        public lazy var controlRadioCheckBorder: UIColor = borderCoreDefault
        public lazy var controlRadioCheckIcon: UIColor = textOnAccent
        public lazy var controlToggleSwitchBackground: UIColor = accentNeutral
        public lazy var controlToggleSwitchBackgroundDisabled: UIColor = backgroundUtilityDisabled
        public lazy var controlToggleSwitchBackgroundSelected: UIColor = accentPrimary
        public lazy var controlToggleSwitchKnob: UIColor = backgroundCoreOnAccent

        // MARK: - Input

        public lazy var inputTextDefault: UIColor = textPrimary
        public lazy var inputTextDisabled: UIColor = textDisabled
        public lazy var inputTextIcon: UIColor = textTertiary
        public lazy var inputTextIconActive: UIColor = textPrimary
        public lazy var inputTextPlaceholder: UIColor = textTertiary

        // MARK: - Label

        public lazy var labelBackgroundNeutral: UIColor = palette.chrome150
        public lazy var labelBackgroundPrimary: UIColor = palette.brand150
        public lazy var labelTextNeutral: UIColor = textPrimary
        public lazy var labelTextPrimary: UIColor = palette.brand900

        // MARK: - System

        public lazy var systemBackgroundBlur: UIColor = UIColor(light: UIColor(hex: 0xffffff03), dark: UIColor(hex: 0x00000003))
        public lazy var systemCaret: UIColor = accentPrimary
        public lazy var systemScrollbar: UIColor = UIColor(light: UIColor(hex: 0x00000080), dark: UIColor(hex: 0xffffff80))
        public lazy var systemText: UIColor = palette.chrome1000

        // MARK: - Tab

        public lazy var tabIndicator: UIColor = accentPrimary
        public lazy var tabText: UIColor = textSecondary
        public lazy var tabTextSelected: UIColor = accentPrimary
        public lazy var tabTrack: UIColor = borderCoreDefault

        // MARK: - Text

        public lazy var textDisabled: UIColor = palette.chrome300
        public lazy var textLink: UIColor = UIColor(light: palette.brand500, dark: palette.brand600)
        public lazy var textOnAccent: UIColor = UIColor(light: palette.chrome0, dark: palette.chrome1000)
        public lazy var textOnInverse: UIColor = palette.chrome0
        public lazy var textPrimary: UIColor = palette.chrome900
        public lazy var textSecondary: UIColor = palette.chrome700
        public lazy var textTertiary: UIColor = palette.chrome500

        public init(palette: Palette = Palette()) {
            self.palette = palette
        }
    }
}
