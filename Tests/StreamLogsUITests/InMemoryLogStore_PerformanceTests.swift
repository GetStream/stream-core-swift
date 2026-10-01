//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamLogsUI
import XCTest

final class InMemoryLogStore_PerformanceTests: XCTestCase {
    func test_append_beyondCapacityWithSubscriber() {
        let entries = (0..<50000).map { index in
            LogEntry(
                level: .debug,
                subsystems: ["httpRequests"],
                message: "Request \(index) finished with a response body",
                functionName: "decodeRequestResponse()",
                fileName: "RequestDecoder.swift",
                lineNumber: 89
            )
        }

        measure {
            let store = InMemoryLogStore(capacity: 5000)
            let cancellable = store.entriesPublisher.sink { _ in }
            entries.forEach(store.append)
            XCTAssertLessThanOrEqual(store.entries.count, 5000)
            cancellable.cancel()
        }
    }
}
