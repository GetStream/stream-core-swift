//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import UIKit
import XCTest

@MainActor
final class Appearance_Tests: XCTestCase {
    private lazy var subject: Appearance! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Composition

    func test_init_injectedPaletteIsUsed() {
        let palette = ColorPalette()

        subject = .init(colorPalette: palette)

        XCTAssertTrue(subject.colorPalette === palette)
    }

    func test_separateInstances_overrideDoesNotLeakBetweenThem() {
        let other = Appearance()

        subject.colorPalette.brand500 = .magenta

        XCTAssertNotEqual(other.colorPalette.brand500, .magenta)
    }

    func test_sharedInstance_isStable() {
        XCTAssertTrue(Appearance.shared === Appearance.shared)
        XCTAssertTrue(Appearance.default === Appearance.shared)
    }

    // MARK: - Bags

    func test_bag_firstRead_createsDefaultInstance() {
        let first = subject[TestBag.self]
        let second = subject[TestBag.self]

        XCTAssertTrue(first === second)
    }

    func test_bag_assignedValue_isReturned() {
        let bag = TestBag()
        bag.flag = true

        subject[TestBag.self] = bag

        XCTAssertTrue(subject[TestBag.self] === bag)
        XCTAssertTrue(subject[TestBag.self].flag)
    }

    func test_bag_separateAppearances_doNotShareBags() {
        let other = Appearance()
        subject[TestBag.self].flag = true

        XCTAssertFalse(other[TestBag.self].flag)
    }
}

private final class TestBag: AppearanceBag {
    var flag = false

    required init() { /* Test init. */ }
}
