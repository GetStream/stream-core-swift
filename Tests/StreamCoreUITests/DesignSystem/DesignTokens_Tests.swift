//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import UIKit
import XCTest

final class DesignTokens_Tests: XCTestCase {
    private lazy var subject: DesignTokens! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Isolation

    func test_separateInstances_overrideDoesNotLeakBetweenThem() {
        let other = DesignTokens()

        subject.colors.brand500 = .magenta

        XCTAssertNotEqual(other.colors.brand500, .magenta)
    }

    func test_init_injectedGroupsAreUsed() {
        let colors = DesignTokens.Colors()
        let layout = DesignTokens.Layout()

        subject = .init(colors: colors, layout: layout)

        XCTAssertTrue(subject.colors === colors)
        XCTAssertTrue(subject.layout === layout)
    }

    // MARK: - Colour ramps

    func test_chromeRampOverridden_beforeFirstRead_derivedTokenUsesOverride() {
        subject.colors.chrome500 = .magenta

        XCTAssertEqual(subject.colors.accentNeutral, .magenta)
        XCTAssertEqual(subject.colors.textTertiary, .magenta)
    }

    func test_chromeRampOverridden_afterFirstRead_derivedTokenKeepsResolvedValue() {
        let original = subject.colors.accentNeutral

        subject.colors.chrome500 = .magenta

        XCTAssertEqual(subject.colors.accentNeutral, original)
    }

    func test_brandRampOverridden_beforeFirstRead_derivedTokenUsesOverride() {
        subject.colors.brand150 = .magenta

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
}
