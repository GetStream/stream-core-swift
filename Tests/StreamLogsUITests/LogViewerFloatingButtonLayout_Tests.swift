//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamLogsUI
import UIKit
import XCTest

final class LogViewerFloatingButtonLayout_Tests: XCTestCase {
    private let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let safeAreaInsets = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)

    // MARK: - Center

    func test_center_default_isOnTheRightEdgeOfTheSafeArea() {
        let center = LogViewerFloatingButtonLayout().center(in: bounds, safeAreaInsets: safeAreaInsets)

        XCTAssertEqual(center.x, 350, accuracy: 0.001)
        XCTAssertEqual(center.y, 87 + 0.85 * 683, accuracy: 0.001)
    }

    func test_center_leftSide_isOnTheLeftEdgeOfTheSafeArea() {
        let layout = LogViewerFloatingButtonLayout(side: .left)

        XCTAssertEqual(layout.center(in: bounds, safeAreaInsets: safeAreaInsets).x, 40, accuracy: 0.001)
    }

    func test_center_verticalPositionBounds_matchTopAndBottomOfTheSafeArea() {
        let top = LogViewerFloatingButtonLayout(verticalPosition: 0)
        let bottom = LogViewerFloatingButtonLayout(verticalPosition: 1)

        XCTAssertEqual(top.center(in: bounds, safeAreaInsets: safeAreaInsets).y, 87, accuracy: 0.001)
        XCTAssertEqual(bottom.center(in: bounds, safeAreaInsets: safeAreaInsets).y, 770, accuracy: 0.001)
    }

    func test_center_stashed_leavesOnlyAStripVisibleAtTheScreenEdge() {
        let right = LogViewerFloatingButtonLayout(side: .right, isStashed: true)
        let left = LogViewerFloatingButtonLayout(side: .left, isStashed: true)

        XCTAssertEqual(right.center(in: bounds, safeAreaInsets: safeAreaInsets).x, 394, accuracy: 0.001)
        XCTAssertEqual(left.center(in: bounds, safeAreaInsets: safeAreaInsets).x, -4, accuracy: 0.001)
    }

    // MARK: - Released

    func test_released_withoutVelocity_snapsToTheNearestSide() {
        let left = released(at: CGPoint(x: 100, y: 300))
        let right = released(at: CGPoint(x: 300, y: 300))

        XCTAssertEqual(left.side, .left)
        XCTAssertFalse(left.isStashed)
        XCTAssertEqual(right.side, .right)
        XCTAssertFalse(right.isStashed)
    }

    func test_released_flungPastAnEdge_isStashedOnThatSide() {
        let right = released(at: CGPoint(x: 300, y: 300), velocity: CGPoint(x: 1000, y: 0))
        let left = released(at: CGPoint(x: 100, y: 300), velocity: CGPoint(x: -1000, y: 0))

        XCTAssertEqual(right, LogViewerFloatingButtonLayout(side: .right, verticalPosition: right.verticalPosition, isStashed: true))
        XCTAssertEqual(left, LogViewerFloatingButtonLayout(side: .left, verticalPosition: left.verticalPosition, isStashed: true))
    }

    func test_released_partlyOffscreen_isStashed() {
        XCTAssertTrue(released(at: CGPoint(x: 10, y: 300)).isStashed)
        XCTAssertTrue(released(at: CGPoint(x: 380, y: 300)).isStashed)
        XCTAssertFalse(released(at: CGPoint(x: 20, y: 300)).isStashed)
        XCTAssertFalse(released(at: CGPoint(x: 370, y: 300)).isStashed)
    }

    func test_released_flungAcrossTheScreen_movesToTheOtherSide() {
        let layout = released(at: CGPoint(x: 100, y: 300), velocity: CGPoint(x: 2000, y: 0))

        XCTAssertEqual(layout.side, .right)
        XCTAssertTrue(layout.isStashed)
    }

    func test_released_slowFlingTowardsAnEdge_isNotStashed() {
        let layout = released(at: CGPoint(x: 300, y: 300), velocity: CGPoint(x: 200, y: 0))

        XCTAssertEqual(layout.side, .right)
        XCTAssertFalse(layout.isStashed)
    }

    func test_released_outsideTheSafeAreaVertically_clampsVerticalPosition() {
        XCTAssertEqual(released(at: CGPoint(x: 300, y: -100)).verticalPosition, 0)
        XCTAssertEqual(released(at: CGPoint(x: 300, y: 2000)).verticalPosition, 1)
    }

    func test_released_atTheCenterOfALayout_keepsThatLayout() {
        let layout = LogViewerFloatingButtonLayout(side: .left, verticalPosition: 0.25)

        let result = released(at: layout.center(in: bounds, safeAreaInsets: safeAreaInsets))

        XCTAssertEqual(result.side, .left)
        XCTAssertFalse(result.isStashed)
        XCTAssertEqual(result.verticalPosition, 0.25, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func released(at center: CGPoint, velocity: CGPoint = .zero) -> LogViewerFloatingButtonLayout {
        LogViewerFloatingButtonLayout.released(at: center, velocity: velocity, in: bounds, safeAreaInsets: safeAreaInsets)
    }
}
