//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type encapsulating the logic of computing delays for the failed actions that needs to be retried.
public protocol RetryStrategy: Sendable {
    /// Returns the # of consecutively failed retries.
    var consecutiveFailuresCount: Int { get }
    
    /// Increments the # of consecutively failed retries making the next delay longer.
    mutating func incrementConsecutiveFailures()
    
    /// Resets the # of consecutively failed retries making the next delay be the shortest one.
    mutating func resetConsecutiveFailures()
    
    /// Calculates and returns the delay for the next retry.
    ///
    /// Consecutive calls after the same # of failures may return different delays. This randomization is done to
    /// make the retry intervals slightly different for different callers to avoid putting the backend down by
    /// making all the retries at the same time.
    ///
    /// - Returns: The delay for the next retry.
    func nextRetryDelay() -> TimeInterval
}

extension RetryStrategy {
    /// Returns the delay and then increments # of consecutively failed retries.
    ///
    /// - Returns: The delay for the next retry.
    public mutating func getDelayAfterTheFailure() -> TimeInterval {
        defer { incrementConsecutiveFailures() }
        
        return nextRetryDelay()
    }
}

/// The default implementation of `RetryStrategy` with exponentially growing delays.
public struct DefaultRetryStrategy: RetryStrategy {
    static let maximumReconnectionDelay: TimeInterval = 25
    
    @Atomic private(set) public var consecutiveFailuresCount = 0
    
    mutating public func incrementConsecutiveFailures() {
        _consecutiveFailuresCount.mutate { $0 + 1 }
    }
    
    mutating public func resetConsecutiveFailures() {
        consecutiveFailuresCount = 0
    }
    
    public func nextRetryDelay() -> TimeInterval {
        var delay: TimeInterval = 0

        let consecutiveFailuresCount = self.consecutiveFailuresCount
        /// The first time we get to retry, we do it without any delay. Any subsequent time will
        /// be delayed by a random interval.
        guard consecutiveFailuresCount > 0 else { return delay }

        let maxDelay: TimeInterval = min(0.5 + Double(consecutiveFailuresCount * 2), Self.maximumReconnectionDelay)
        let minDelay: TimeInterval = min(max(0.25, (Double(consecutiveFailuresCount) - 1) * 2), Self.maximumReconnectionDelay)

        delay = TimeInterval.random(in: minDelay...maxDelay)

        return delay
    }
    
    public init() {}
}
