//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// Shared colour tokens every Stream SDK draws from.
///
/// - Important: Start by adjusting the `brand` and `chrome` ramps. Most
/// semantic tokens derive from them, so a handful of overrides reskins
/// every SDK that shares this instance. Reach for an individual token
/// only when one surface needs to deviate from what the ramps produce.
///
/// Tokens derive lazily, so override the ramps before the first read.
extension DesignSystemTokens {
    public final class Colors {
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

        // MARK: - Accent

        public lazy var accentError: UIColor = UIColor(light: .red500, dark: .red400)
        public lazy var accentNeutral: UIColor = chrome500
        public lazy var accentPrimary: UIColor = UIColor(light: brand500, dark: brand400)
        public lazy var accentSuccess: UIColor = UIColor(light: .green400, dark: .green300)
        public lazy var accentWarning: UIColor = UIColor(light: .yellow400, dark: .yellow300)

        // MARK: - Avatar

        public lazy var avatarBackgroundDefault: UIColor = avatarPaletteBackground1
        public lazy var avatarBackgroundPlaceholder: UIColor = chrome150
        public lazy var avatarPaletteBackground1: UIColor = UIColor(light: .blue150, dark: .blue600)
        public lazy var avatarPaletteBackground2: UIColor = UIColor(light: .cyan150, dark: .cyan600)
        public lazy var avatarPaletteBackground3: UIColor = UIColor(light: .green150, dark: .green600)
        public lazy var avatarPaletteBackground4: UIColor = UIColor(light: .purple150, dark: .purple600)
        public lazy var avatarPaletteBackground5: UIColor = UIColor(light: .yellow150, dark: .yellow600)
        public lazy var avatarPaletteText1: UIColor = UIColor(light: .blue900, dark: .blue100)
        public lazy var avatarPaletteText2: UIColor = UIColor(light: .cyan900, dark: .cyan100)
        public lazy var avatarPaletteText3: UIColor = UIColor(light: .green900, dark: .green100)
        public lazy var avatarPaletteText4: UIColor = UIColor(light: .purple900, dark: .purple100)
        public lazy var avatarPaletteText5: UIColor = UIColor(light: .yellow900, dark: .yellow100)
        public lazy var avatarPresenceBackgroundOffline: UIColor = accentNeutral
        public lazy var avatarPresenceBackgroundOnline: UIColor = accentSuccess
        public lazy var avatarPresenceBorder: UIColor = borderCoreOnInverse
        public lazy var avatarTextDefault: UIColor = avatarPaletteText1
        public lazy var avatarTextPlaceholder: UIColor = chrome500

        // MARK: - Background

        public lazy var backgroundCoreApp: UIColor = chrome0
        public lazy var backgroundCoreElevation0: UIColor = chrome0
        public lazy var backgroundCoreElevation1: UIColor = UIColor(light: chrome0, dark: chrome50)
        public lazy var backgroundCoreElevation2: UIColor = UIColor(light: chrome0, dark: chrome100)
        public lazy var backgroundCoreElevation3: UIColor = UIColor(light: chrome0, dark: chrome200)
        public lazy var backgroundCoreHighlight: UIColor = UIColor(light: .yellow50, dark: .yellow800)
        public lazy var backgroundCoreInverse: UIColor = chrome1000
        public lazy var backgroundCoreOnAccent: UIColor = UIColor(light: chrome0, dark: chrome1000)
        public lazy var backgroundCoreOverlayDark: UIColor = UIColor(
            light: UIColor(hex: 0x1a1b2540),
            dark: UIColor(hex: 0x00000080)
        )
        public lazy var backgroundCoreOverlayDarkStrong: UIColor = UIColor(
            light: UIColor(hex: 0x1a1b25bf),
            dark: UIColor(hex: 0x000000bf)
        )
        public lazy var backgroundCoreOverlayLight: UIColor = UIColor(
            light: UIColor(hex: 0xffffffbf),
            dark: UIColor(hex: 0x000000bf)
        )
        public lazy var backgroundCoreScrim: UIColor = UIColor(light: UIColor(hex: 0x1a1b2580), dark: UIColor(hex: 0x000000bf))
        public lazy var backgroundCoreSurfaceCard: UIColor = UIColor(light: chrome50, dark: chrome100)
        public lazy var backgroundCoreSurfaceDefault: UIColor = chrome100
        public lazy var backgroundCoreSurfaceStrong: UIColor = chrome150
        public lazy var backgroundCoreSurfaceSubtle: UIColor = chrome50
        public lazy var backgroundUtilityDisabled: UIColor = chrome100
        public lazy var backgroundUtilityHover: UIColor = UIColor(light: UIColor(hex: 0x1a1b251a), dark: UIColor(hex: 0xffffff26))
        public lazy var backgroundUtilityPressed: UIColor = UIColor(light: UIColor(hex: 0x1a1b2526), dark: UIColor(hex: 0xffffff33))
        public lazy var backgroundUtilitySelected: UIColor = UIColor(
            light: UIColor(hex: 0x1a1b2533),
            dark: UIColor(hex: 0xffffff40)
        )

        // MARK: - Badge

        public lazy var badgeBackgroundDefault: UIColor = backgroundCoreElevation3
        public lazy var badgeBackgroundError: UIColor = accentError
        public lazy var badgeBackgroundInverse: UIColor = chrome1000
        public lazy var badgeBackgroundNeutral: UIColor = accentNeutral
        public lazy var badgeBackgroundOverlay: UIColor = UIColor(hex: 0x000000bf)
        public lazy var badgeBackgroundPrimary: UIColor = accentPrimary
        public lazy var badgeBorder: UIColor = borderCoreOnInverse
        public lazy var badgeText: UIColor = textPrimary
        public lazy var badgeTextOnAccent: UIColor = textOnAccent
        public lazy var badgeTextOnInverse: UIColor = textOnInverse

        // MARK: - Border

        public lazy var borderCoreDefault: UIColor = UIColor(light: chrome150, dark: chrome200)
        public lazy var borderCoreInverse: UIColor = chrome0
        public lazy var borderCoreOnAccent: UIColor = UIColor(light: chrome0, dark: chrome1000)
        public lazy var borderCoreOnInverse: UIColor = chrome0
        public lazy var borderCoreOnSurface: UIColor = chrome300
        public lazy var borderCoreOpacityStrong: UIColor = UIColor(light: UIColor(hex: 0x1a1b2540), dark: UIColor(hex: 0xffffff40))
        public lazy var borderCoreOpacitySubtle: UIColor = UIColor(light: UIColor(hex: 0x1a1b251a), dark: UIColor(hex: 0xffffff33))
        public lazy var borderCoreStrong: UIColor = chrome300
        public lazy var borderCoreSubtle: UIColor = chrome100
        public lazy var borderUtilityActive: UIColor = accentPrimary
        public lazy var borderUtilityDisabled: UIColor = chrome100
        public lazy var borderUtilityDisabledOnSurface: UIColor = chrome150
        public lazy var borderUtilityError: UIColor = accentError
        public lazy var borderUtilityFocused: UIColor = brand150
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
        public lazy var buttonPrimaryBorder: UIColor = brand200
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
        public lazy var controlPlaybackThumbBackgroundActive: UIColor = accentPrimary
        public lazy var controlPlaybackThumbBackgroundDefault: UIColor = backgroundCoreOnAccent
        public lazy var controlPlaybackThumbBorderActive: UIColor = borderCoreOnAccent
        public lazy var controlPlaybackThumbBorderDefault: UIColor = borderCoreOpacityStrong
        public lazy var controlPlaybackToggleBorder: UIColor = borderCoreDefault
        public lazy var controlPlaybackToggleText: UIColor = textPrimary
        public lazy var controlPlayButtonBackground: UIColor = UIColor(hex: 0x000000bf)
        public lazy var controlPlayButtonIcon: UIColor = textOnAccent
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
        public lazy var controlRemoveControlBackground: UIColor = backgroundCoreInverse
        public lazy var controlRemoveControlBorder: UIColor = borderCoreOnInverse
        public lazy var controlRemoveControlIcon: UIColor = textOnInverse
        public lazy var controlToggleSwitchBackground: UIColor = accentNeutral
        public lazy var controlToggleSwitchBackgroundDisabled: UIColor = backgroundUtilityDisabled
        public lazy var controlToggleSwitchBackgroundSelected: UIColor = accentPrimary
        public lazy var controlToggleSwitchKnob: UIColor = backgroundCoreOnAccent

        // MARK: - Input

        public lazy var inputSendIcon: UIColor = accentPrimary
        public lazy var inputSendIconDisabled: UIColor = textDisabled
        public lazy var inputTextDefault: UIColor = textPrimary
        public lazy var inputTextDisabled: UIColor = textDisabled
        public lazy var inputTextIcon: UIColor = textTertiary
        public lazy var inputTextIconActive: UIColor = textPrimary
        public lazy var inputTextPlaceholder: UIColor = textTertiary

        // MARK: - Presence

        public lazy var presenceBackgroundOffline: UIColor = avatarPresenceBackgroundOffline
        public lazy var presenceBackgroundOnline: UIColor = avatarPresenceBackgroundOnline
        public lazy var presenceBorder: UIColor = avatarPresenceBorder

        // MARK: - Reaction

        public lazy var reactionBackground: UIColor = backgroundCoreElevation3
        public lazy var reactionBorder: UIColor = borderCoreDefault
        public lazy var reactionEmoji: UIColor = textPrimary
        public lazy var reactionText: UIColor = textPrimary

        // MARK: - Skeleton

        public lazy var skeletonLoadingBase: UIColor = .baseTransparent0
        public lazy var skeletonLoadingHighlight: UIColor = backgroundCoreOverlayLight

        // MARK: - System

        public lazy var systemBackgroundBlur: UIColor = UIColor(light: UIColor(hex: 0xffffff03), dark: UIColor(hex: 0x00000003))
        public lazy var systemCaret: UIColor = accentPrimary
        public lazy var systemScrollbar: UIColor = UIColor(light: UIColor(hex: 0x00000080), dark: UIColor(hex: 0xffffff80))
        public lazy var systemText: UIColor = chrome1000

        // MARK: - Text

        public lazy var textDisabled: UIColor = chrome300
        public lazy var textLink: UIColor = UIColor(light: brand500, dark: brand600)
        public lazy var textOnAccent: UIColor = UIColor(light: chrome0, dark: chrome1000)
        public lazy var textOnInverse: UIColor = chrome0
        public lazy var textPrimary: UIColor = chrome900
        public lazy var textSecondary: UIColor = chrome700
        public lazy var textTertiary: UIColor = chrome500

        public init() { /* Public init. */ }
    }
}
