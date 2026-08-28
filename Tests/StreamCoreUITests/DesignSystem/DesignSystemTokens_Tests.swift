//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import XCTest

final class DesignSystemTokens_Tests: XCTestCase {
    private lazy var subject: DesignSystemTokens! = .init()

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

    func test_radiusOverridden_beforeFirstRead_messagingTokenUsesOverride() {
        subject.radius2xl = 99

        XCTAssertEqual(subject.messageBubbleRadiusGroupTop, 99)
    }
}
