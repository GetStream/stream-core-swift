//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// RFC3339 date formatter.
public struct RFC3339DateFormatter: Sendable {
    private static let shared = RFC3339DateFormatter()
    
    public static func string(from date: Date) -> String {
        shared.string(from: date)
    }
    
    func string(from date: Date) -> String {
        formatter.string(from: date)
    }
    
    /// Parses an RFC3339 timestamp with optional fractional seconds.
    public static func date(from dateString: String) -> Date? {
        shared.date(from: dateString)
    }
    
    func date(from dateString: String) -> Date? {
        formatter.dateWithMicroseconds(from: dateString) ?? DateFormatter.Stream.rfc3339Date(from: dateString)
    }

    private nonisolated(unsafe) let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

extension ISO8601DateFormatter {
    func dateWithMicroseconds(from string: String) -> Date? {
        guard let date = date(from: string) else { return nil }
        // ISO8601DateFormatter is limited to milliseconds, so the fraction is parsed manually. The result is
        // built from whole nanoseconds, the same way as dates sent as integer nanoseconds, so that one instant
        // decodes to the same `Date` in both formats.
        guard let index = string.lastIndex(of: ".") else { return date }
        let digits = string[string.index(after: index)...].prefix(while: \.isASCIIDigit).prefix(9)
        guard !digits.isEmpty, let fraction = Int64(digits.padding(toLength: 9, withPad: "0", startingAt: 0)) else {
            return date
        }
        let seconds = Int64(date.timeIntervalSince1970.rounded(.down))
        return Date(unixNanoseconds: Double(seconds * 1_000_000_000 + fraction))
    }
}

extension Date {
    init(unixNanoseconds: Double) {
        self.init(timeIntervalSince1970: unixNanoseconds / 1_000_000_000)
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}
