//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamCore
import XCTest

final class RepeatingTimer_Tests: XCTestCase, @unchecked Sendable {
    func test_scheduleRepeating_waitsForConfiguredIntervalBetweenFires() {
        let interval: TimeInterval = 0.2
        let startedAt = DispatchTime.now().uptimeNanoseconds
        var fireTimes: [UInt64] = []
        let fired = expectation(description: "Timer fired twice")
        fired.expectedFulfillmentCount = 2
        let repeatingTimer = DefaultTimer.scheduleRepeating(
            timeInterval: interval,
            queue: .main
        ) {
            fireTimes.append(DispatchTime.now().uptimeNanoseconds)
            fired.fulfill()
        }

        repeatingTimer.resume()
        wait(for: [fired], timeout: 2)
        repeatingTimer.suspend()

        guard fireTimes.count == 2 else {
            return XCTFail("Expected exactly two timer fires.")
        }
        XCTAssertGreaterThanOrEqual(
            TimeInterval(fireTimes[0] - startedAt) / 1_000_000_000,
            interval / 2
        )
        XCTAssertGreaterThanOrEqual(
            TimeInterval(fireTimes[1] - fireTimes[0]) / 1_000_000_000,
            interval / 2
        )
    }

    func test_state_isThreadSafe() {
        DispatchQueue.concurrentPerform(iterations: 10000) { _ in
            let repeatingTimer: RepeatingTimerControl? = DefaultTimer.scheduleRepeating(
                timeInterval: 0.4,
                queue: .main,
                onFire: {}
            )
            repeatingTimer?.resume()
            repeatingTimer?.suspend()
        }
    }

    func test_deinit_whenResumed_doesNotCrash() {
        var repeatingTimer: RepeatingTimerControl? = DefaultTimer.scheduleRepeating(
            timeInterval: 0.4,
            queue: .main,
            onFire: {}
        )
        repeatingTimer?.resume()
        repeatingTimer = nil
    }

    func test_deinit_whenSuspended_doesNotCrash() {
        var repeatingTimer: RepeatingTimerControl? = DefaultTimer.scheduleRepeating(
            timeInterval: 0.4,
            queue: .main,
            onFire: {}
        )
        repeatingTimer?.suspend()
        repeatingTimer = nil
    }
}
