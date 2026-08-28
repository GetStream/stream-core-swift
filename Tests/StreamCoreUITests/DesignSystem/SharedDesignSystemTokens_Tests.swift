//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import XCTest

final class SharedDesignSystemTokens_Tests: XCTestCase {
    private lazy var subject: SharedDesignSystemTokens! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Scale overrides

    func test_radiusOverridden_beforeFirstRead_derivedTokenUsesOverride() {
        subject.radiusXl = 99

        XCTAssertEqual(subject.inputRadiusTextInput, 99)
    }

    func test_radiusOverridden_afterFirstRead_derivedTokenKeepsResolvedValue() {
        let original = subject.inputRadiusTextInput

        subject.radiusXl = 99

        XCTAssertEqual(subject.inputRadiusTextInput, original)
    }

    func test_semanticTokenOverridden_readsBackOverride() {
        subject.spacingMd = 99

        XCTAssertEqual(subject.spacingMd, 99)
    }
}
