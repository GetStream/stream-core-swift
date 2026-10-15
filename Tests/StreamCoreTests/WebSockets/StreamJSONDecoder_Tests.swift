//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamCore
import XCTest

final class StreamJSONDecoderTests: XCTestCase {
    private var streamJSONDecoder: StreamJSONDecoder!
    
    override func setUpWithError() throws {
        streamJSONDecoder = StreamJSONDecoder()
    }
    
    override func tearDownWithError() throws {
        streamJSONDecoder = nil
    }
    
    func test_parsingDate_whenMicroseconds_thenReturnsDateWithMicroseconds() throws {
        let jsonData = jsonDataForItem(withDateString: "2024-06-24T21:00:33.167806Z")
        let item = try streamJSONDecoder.decode(Item.self, from: jsonData)
        XCTAssertEqual(1_719_262_833.167_806, item.date.timeIntervalSince1970, accuracy: 0.000_000_5)
    }
    
    func test_parsingDate_whenMicrosecondsTruncated_thenReturnsDateWithMicroseconds() throws {
        // Last 0 is not there
        let jsonData = jsonDataForItem(withDateString: "2024-06-14T16:24:37.63784Z")
        let item = try streamJSONDecoder.decode(Item.self, from: jsonData)
        XCTAssertEqual(1_718_382_277.637_840, item.date.timeIntervalSince1970, accuracy: 0.000_000_5)
        
        let jsonData2 = jsonDataForItem(withDateString: "2024-06-14T16:24:37.637840Z")
        let item2 = try streamJSONDecoder.decode(Item.self, from: jsonData2)
        XCTAssertEqual(1_718_382_277.637_840, item2.date.timeIntervalSince1970, accuracy: 0.000_000_5)
    }
    
    func test_parsingDate_whenNanoseconds_thenReturnsDateWithTruncatedNanoseconds() throws {
        // Date intervals around 2024 are only precise to a few hundred nanoseconds
        let jsonData = jsonDataForItem(withDateString: "2024-09-18T13:49:11.324282561Z")
        let item = try streamJSONDecoder.decode(Item.self, from: jsonData)
        XCTAssertEqual(1_726_667_351.324_282_561, item.date.timeIntervalSince1970, accuracy: 0.000_000_5)
    }

    func test_parsingDate_whenSameInstantAsStringAndNanoseconds_thenDatesAreEqual() throws {
        let pairs = [
            ("2026-10-14T16:37:49.351796Z", "1791995869351796000"),
            ("2026-10-14T16:48:57.232518Z", "1791996537232518000"),
            ("2026-10-14T16:48:57.2325Z", "1791996537232500000"),
            ("2026-10-14T16:48:57Z", "1791996537000000000"),
            ("2024-09-18T13:49:11.324282561Z", "1726667351324282561")
        ]
        for (string, nanoseconds) in pairs {
            let fromString = try streamJSONDecoder.decode(Item.self, from: jsonDataForItem(withDateString: string)).date
            let fromNanoseconds = try streamJSONDecoder.decode(Item.self, from: jsonDataForItem(withRawValue: nanoseconds)).date
            XCTAssertEqual(fromString, fromNanoseconds, string)
        }
    }

    func test_parsingDate_whenMicrosecondsAsStringAndNanoseconds_thenDatesAreEqualForEveryFraction() throws {
        let seconds: Int64 = 1_791_995_869
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let prefix = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds))).dropLast()
        for microseconds in stride(from: 0, to: 1_000_000, by: 997) {
            let fraction = String(format: "%06d", microseconds)
            let nanoseconds = seconds * 1_000_000_000 + Int64(microseconds) * 1000
            let fromString = try streamJSONDecoder.decode(Item.self, from: jsonDataForItem(withDateString: "\(prefix).\(fraction)Z")).date
            let fromNanoseconds = try streamJSONDecoder.decode(Item.self, from: jsonDataForItem(withRawValue: "\(nanoseconds)")).date
            XCTAssertEqual(fromString, fromNanoseconds, fraction)
        }
    }

    func test_parsingDate_whenTimezoneOffset_thenKeepsMicroseconds() throws {
        let jsonData = jsonDataForItem(withDateString: "2024-06-24T23:00:33.167806+02:00")
        let item = try streamJSONDecoder.decode(Item.self, from: jsonData)
        XCTAssertEqual(1_719_262_833.167_806, item.date.timeIntervalSince1970, accuracy: 0.000_000_5)
    }
}

private extension StreamJSONDecoderTests {
    struct Item: Codable {
        let date: Date
    }
    
    func jsonDataForItem(withDateString dateString: String) -> Data {
        let string = """
        {
          "date": "\(dateString)"
        }
        """
        return Data(string.utf8)
    }

    func jsonDataForItem(withRawValue rawValue: String) -> Data {
        Data("{ \"date\": \(rawValue) }".utf8)
    }
}
