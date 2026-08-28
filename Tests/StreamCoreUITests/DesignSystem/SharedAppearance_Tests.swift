//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import UIKit
import XCTest

final class SharedAppearance_Tests: XCTestCase {
    private lazy var subject: SharedAppearance! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Composition

    func test_init_injectedPaletteIsUsed() {
        let colors = SharedColorPalette()

        subject = .init(colors: colors)

        XCTAssertTrue(subject.colors === colors)
    }

    func test_separateInstances_overrideDoesNotLeakBetweenThem() {
        let other = SharedAppearance()

        subject.colors.brand500 = .magenta

        XCTAssertNotEqual(other.colors.brand500, .magenta)
    }

    func test_sharedInstance_isStable() {
        XCTAssertTrue(SharedAppearance.shared === SharedAppearance.shared)
    }
}
