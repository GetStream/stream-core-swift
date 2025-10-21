//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public protocol StreamTimer {
    /// Schedules a new timer.
    ///
    /// - Parameters:
    ///   - timeInterval: The number of seconds after which the timer fires.
    ///   - queue: The queue on which the `onFire` callback is called.
    ///   - onFire: Called when the timer fires.
    /// - Returns: `TimerControl` where you can cancel the timer.
    @discardableResult
    static func schedule(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) -> TimerControl
    
    /// Schedules a new repeating timer.
    ///
    /// - Parameters:
    ///   - timeInterval: The number of seconds between timer fires.
    ///   - queue: The queue on which the `onFire` callback is called.
    ///   - onFire: Called when the timer fires.
    /// - Returns: `RepeatingTimerControl` where you can suspend and resume the timer.
    static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl
    
    /// Returns the current date and time.
    static func currentTime() -> Date
}

extension StreamTimer {
    public static func currentTime() -> Date {
        Date()
    }
}

/// Allows resuming and suspending of a timer.
public protocol RepeatingTimerControl {
    /// Resumes the timer.
    func resume()
    
    /// Pauses the timer.
    func suspend()
}

/// Allows cancelling a timer.
public protocol TimerControl {
    /// Cancels the timer.
    func cancel()
}

extension DispatchWorkItem: TimerControl {}

/// Default real-world implementations of timers.
public struct DefaultTimer: StreamTimer {
    @discardableResult
    public static func schedule(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> TimerControl {
        let worker = DispatchWorkItem(block: onFire)
        queue.asyncAfter(deadline: .now() + timeInterval, execute: worker)
        return worker
    }
    
    public static func scheduleRepeating(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) -> RepeatingTimerControl {
        RepeatingTimer(timeInterval: timeInterval, queue: queue, onFire: onFire)
    }
    
    /// Returns a Combine publisher that emits `Date` values at a fixed interval.
    ///
    /// The timer operates on a background queue and only emits values while
    /// there are active subscribers. If the interval is less than or equal to
    /// zero, a warning is logged and a single `Date` value is emitted instead.
    ///
    /// - Parameters:
    ///   - interval: Time between emitted date values.
    ///   - file: The file from which the method is called. Used for logging.
    ///   - function: The function from which the method is called.
    ///   - line: The line number from which the method is called.
    /// - Returns: A publisher that emits dates while subscribed.
    public static func publish(
        every interval: TimeInterval,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> AnyPublisher<Date, Never> {
        guard interval > 0 else {
            log.warning(
                "Interval cannot be 0 or less",
                functionName: function,
                fileName: file,
                lineNumber: line
            )
            return Just(Date()).eraseToAnyPublisher()
        }
        return TimerPublisher(interval: interval).eraseToAnyPublisher()
    }
}

private class RepeatingTimer: RepeatingTimerControl, @unchecked Sendable {
    private enum State {
        case suspended
        case resumed
    }

    private let queue = DispatchQueue(label: "io.getstream.repeating-timer")
    private var state: State = .suspended
    private let timer: DispatchSourceTimer

    init(timeInterval: TimeInterval, queue: DispatchQueue, onFire: @escaping () -> Void) {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + .milliseconds(Int(timeInterval)), repeating: timeInterval, leeway: .seconds(1))
        timer.setEventHandler(handler: onFire)
    }

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        // If the timer is suspended, calling cancel without resuming
        // triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
        if state == .suspended {
            timer.resume()
        }
    }

    func resume() {
        queue.async {
            if self.state == .resumed {
                return
            }

            self.state = .resumed
            self.timer.resume()
        }
    }

    func suspend() {
        queue.async {
            if self.state == .suspended {
                return
            }

            self.state = .suspended
            self.timer.suspend()
        }
    }
}
