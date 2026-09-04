//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import SwiftUI
import XCTest

final class DesignSystemTokens_Tests: XCTestCase {
    private lazy var subject: DesignSystemTokens! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Isolation

    func test_separateInstances_overrideDoesNotLeakBetweenThem() {
        let other = DesignSystemTokens()

        subject.colors.palette.brand500 = .magenta

        XCTAssertNotEqual(other.colors.palette.brand500, .magenta)
    }

    func test_init_injectedGroupsAreUsed() {
        let palette = DesignSystemTokens.Colors.Palette()
        let colors = DesignSystemTokens.Colors(palette: palette)
        let layout = DesignSystemTokens.Layout()
        let fonts = DesignSystemTokens.Fonts()

        subject = .init(colors: colors, layout: layout, fonts: fonts)

        XCTAssertTrue(subject.colors === colors)
        XCTAssertTrue(subject.colors.palette === palette)
        XCTAssertTrue(subject.layout === layout)
        XCTAssertTrue(subject.fonts === fonts)
    }

    // MARK: - Palette

    func test_chromeRampOverridden_beforeFirstRead_derivedTokenUsesOverride() {
        subject.colors.palette.chrome500 = .magenta

        XCTAssertEqual(subject.colors.accentNeutral, .magenta)
        XCTAssertEqual(subject.colors.textTertiary, .magenta)
    }

    func test_chromeRampOverridden_afterFirstRead_derivedTokenKeepsResolvedValue() {
        let original = subject.colors.accentNeutral

        subject.colors.palette.chrome500 = .magenta

        XCTAssertEqual(subject.colors.accentNeutral, original)
    }

    func test_brandRampOverridden_beforeFirstRead_derivedTokenUsesOverride() {
        subject.colors.palette.brand150 = .magenta

        XCTAssertEqual(subject.colors.borderUtilityFocused, .magenta)
    }

    func test_accentPrimary_write_readsBack() {
        subject.colors.accentPrimary = .red

        XCTAssertEqual(subject.colors.accentPrimary, .red)
    }

    // MARK: - Layout

    func test_radiusOverridden_beforeFirstRead_derivedTokenUsesOverride() {
        subject.layout.radiusXl = 99

        XCTAssertEqual(subject.layout.inputRadiusTextInput, 99)
    }

    func test_radiusOverridden_afterFirstRead_derivedTokenKeepsResolvedValue() {
        let original = subject.layout.inputRadiusTextInput

        subject.layout.radiusXl = 99

        XCTAssertEqual(subject.layout.inputRadiusTextInput, original)
    }

    func test_semanticTokenOverridden_readsBackOverride() {
        subject.layout.spacingMd = 99

        XCTAssertEqual(subject.layout.spacingMd, 99)
    }

    // MARK: - Fonts

    func test_fontOverridden_readsBackOverride() {
        let custom = Font.system(size: 99)

        subject.fonts.body = custom

        XCTAssertEqual(subject.fonts.body, custom)
    }

    func test_separateInstances_fontOverrideDoesNotLeakBetweenThem() {
        let other = DesignSystemTokens()
        let custom = Font.system(size: 99)

        subject.fonts.body = custom

        XCTAssertNotEqual(other.fonts.body, custom)
    }
}
