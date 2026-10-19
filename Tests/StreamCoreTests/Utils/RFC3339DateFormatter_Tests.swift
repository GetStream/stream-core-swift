//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import XCTest

final class RFC3339DateFormatter_Tests: XCTestCase {
    func test_date_withoutFraction_parsesUTCAndOffsets() {
        let expected = Date(timeIntervalSince1970: 1_704_164_645)
        let timestamps = [
            "2024-01-02T03:04:05Z",
            "2024-01-02T05:34:05+02:30",
            "2024-01-01T22:04:05-05:00"
        ]

        for timestamp in timestamps {
            XCTAssertEqual(RFC3339DateFormatter.date(from: timestamp), expected, timestamp)
        }
    }

    func test_date_withFraction_preservesNanosecondNormalizedPrecision() {
        for precision in 1...9 {
            let fraction = String("123456789".prefix(precision))
            let nanoseconds = Int64(fraction.padding(toLength: 9, withPad: "0", startingAt: 0))!
            let expected = Date(timeIntervalSince1970: Double(1_704_164_645_000_000_000 + nanoseconds) / 1_000_000_000)
            let timestamp = "2024-01-02T03:04:05.\(fraction)Z"

            XCTAssertEqual(RFC3339DateFormatter.date(from: timestamp), expected, timestamp)
        }
    }

    func test_date_withFraction_parsesOffsets() {
        let expected = Date(timeIntervalSince1970: Double(1_704_164_645_123_456_789 as Int64) / 1_000_000_000)
        let timestamps = [
            "2024-01-02T05:34:05.123456789+02:30",
            "2024-01-01T22:04:05.123456789-05:00"
        ]

        for timestamp in timestamps {
            XCTAssertEqual(RFC3339DateFormatter.date(from: timestamp), expected, timestamp)
        }
    }

    func test_date_withInvalidInput_returnsNil() {
        let timestamps = [
            "",
            "invalid",
            "1704164645",
            "1704164645.123456789",
            "2024-01-02T03:04:05",
            "2024-01-02T03:04:05.123456789"
        ]

        for timestamp in timestamps {
            XCTAssertNil(RFC3339DateFormatter.date(from: timestamp), timestamp)
        }
    }

    func test_string_preservesFractionalOutput() {
        let date = Date(timeIntervalSince1970: 1_704_164_645.125)

        XCTAssertEqual(RFC3339DateFormatter.string(from: date), "2024-01-02T03:04:05.125Z")
    }
}
