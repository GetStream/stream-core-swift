//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import UIKit
import XCTest

final class SharedColorPalette_Tests: XCTestCase {
    private lazy var subject: SharedColorPalette! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Ramp overrides

    func test_chromeRampOverridden_beforeFirstRead_derivedTokenUsesOverride() {
        subject.chrome500 = .magenta

        XCTAssertEqual(subject.accentNeutral, .magenta)
        XCTAssertEqual(subject.textTertiary, .magenta)
    }

    func test_chromeRampOverridden_afterFirstRead_derivedTokenKeepsResolvedValue() {
        let original = subject.accentNeutral

        subject.chrome500 = .magenta

        XCTAssertEqual(subject.accentNeutral, original)
    }

    func test_brandRampOverridden_beforeFirstRead_derivedTokenUsesOverride() {
        subject.brand150 = .magenta

        XCTAssertEqual(subject.borderUtilityFocused, .magenta)
    }
}
