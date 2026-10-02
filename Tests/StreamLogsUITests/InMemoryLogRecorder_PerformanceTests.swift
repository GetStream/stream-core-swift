//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamLogsUI
import XCTest

final class InMemoryLogRecorder_PerformanceTests: XCTestCase {
    func test_record_beyondCapacityWithSubscriber() {
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
            let recorder = InMemoryLogRecorder(capacity: 5000)
            let cancellable = recorder.entriesPublisher.sink { _ in }
            entries.forEach(recorder.record)
            XCTAssertLessThanOrEqual(recorder.entries.count, 5000)
            cancellable.cancel()
        }
    }
}
