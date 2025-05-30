//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import protocol StreamCore.Timer

struct VirtualTimeTimer: Timer {
    static nonisolated(unsafe) var time: VirtualTime!

    static func invalidate() {
        time.invalidate()
        time = nil
    }

    static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> TimerControl {
        Self.time.scheduleTimer(
            interval: timeInterval,
            repeating: false,
            callback: { _ in onFire() }
        )
    }

    static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl {
        Self.time.scheduleTimer(
            interval: timeInterval,
            repeating: true,
            callback: { _ in onFire() }
        )
    }

    static func currentTime() -> Date {
        Date(timeIntervalSinceReferenceDate: time.currentTime)
    }
}

extension VirtualTime.TimerControl: TimerControl, RepeatingTimerControl {}
