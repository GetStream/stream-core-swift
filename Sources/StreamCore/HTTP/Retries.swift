//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

func executeTask<Output>(
    retryPolicy: RetryPolicy,
    task: () async throws -> Output,
    shouldRetryError: (Error) -> Bool = { $0.hasClientErrors }
) async throws -> Output {
    try await executeTask(
        retryPolicy: retryPolicy,
        task: task,
        retries: 0,
        shouldRetryError: shouldRetryError
    )
}

func executeTask<Output>(
    retryPolicy: RetryPolicy,
    task: () async throws -> Output,
    retries: Int,
    shouldRetryError: (Error) -> Bool
) async throws -> Output {
    do {
        return try await task()
    } catch {
        if retries < retryPolicy.maxRetries && shouldRetryError(error) {
            let delay = UInt64(retryPolicy.delay(retries) * 1_000_000_000)
            try await Task.sleep(nanoseconds: delay)
            if await retryPolicy.runPrecondition() {
                return try await executeTask(
                    retryPolicy: retryPolicy,
                    task: task,
                    retries: retries + 1,
                    shouldRetryError: shouldRetryError
                )
            } else {
                throw error
            }
        } else {
            throw error
        }
    }
}

struct RetryPolicy: Sendable {
    let maxRetries: Int
    let delay: @Sendable(Int) -> TimeInterval
    var runPrecondition: @Sendable() async -> Bool = { true }
}

extension RetryPolicy {
    static let fastAndSimple = RetryPolicy(maxRetries: 3) { quickDelay(retries: $0) }

    static func fastCheckValue(_ condition: @Sendable @escaping () -> Bool) -> RetryPolicy {
        RetryPolicy(
            maxRetries: 3,
            delay: { quickDelay(retries: $0) },
            runPrecondition: condition
        )
    }
    
    static func neverGonnaGiveYouUp(_ condition: @Sendable @escaping () async -> Bool) -> RetryPolicy {
        RetryPolicy(
            maxRetries: 30,
            delay: { delay(retries: $0) },
            runPrecondition: condition
        )
    }
    
    static func quickDelay(retries: Int) -> TimeInterval {
        TimeInterval.random(in: 0.25...0.5)
    }
    
    static func delay(retries: Int) -> TimeInterval {
        TimeInterval.random(in: 0.5...2.5)
    }
}
