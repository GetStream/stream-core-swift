//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamCore
import XCTest

final class RepeatingTimer_Tests: XCTestCase, @unchecked Sendable {
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

    func test_scheduleRepeating_doesNotFireBeforeInterval() {
        let interval: TimeInterval = 0.2
        let timerDidFire = expectation(description: "Timer fires")
        timerDidFire.isInverted = true

        let subject = DefaultTimer.scheduleRepeating(
            timeInterval: interval,
            queue: .global(),
            onFire: { timerDidFire.fulfill() }
        )
        subject.resume()

        wait(for: [timerDidFire], timeout: interval / 2)
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
