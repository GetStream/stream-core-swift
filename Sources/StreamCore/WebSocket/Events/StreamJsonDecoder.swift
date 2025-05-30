//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - JSONDecoder Stream

public final class StreamJSONDecoder: JSONDecoder, @unchecked Sendable {
    let iso8601formatter: ISO8601DateFormatter
    let dateCache: NSCache<NSString, NSDate>
    
    override convenience init() {
        let iso8601formatter = ISO8601DateFormatter()
        iso8601formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        
        let dateCache = NSCache<NSString, NSDate>()
        dateCache.countLimit = 5000 // We cache at most 5000 dates, which gives good enough performance
        
        self.init(dateFormatter: iso8601formatter, dateCache: dateCache)
    }
    
    init(dateFormatter: ISO8601DateFormatter, dateCache: NSCache<NSString, NSDate>) {
        iso8601formatter = dateFormatter
        self.dateCache = dateCache
        
        super.init()
        
        dateDecodingStrategy = .custom { [weak self] decoder throws -> Date in
            let container = try decoder.singleValueContainer()
            
            do {
                let interval: Double = try container.decode(Double.self) / 1_000_000_000
                let date = Date(timeIntervalSince1970: interval)
                return date
            } catch {
                let dateString: String = try container.decode(String.self)
                
                if let date = self?.dateCache.object(forKey: dateString as NSString) {
                    return date.bridgeDate
                }
                
                if let date = self?.iso8601formatter.date(from: dateString) {
                    self?.dateCache.setObject(date.bridgeDate, forKey: dateString as NSString)
                    return date
                }
                
                if let date = DateFormatter.Stream.rfc3339Date(from: dateString) {
                    self?.dateCache.setObject(date.bridgeDate, forKey: dateString as NSString)
                    return date
                }
                
                // Fail
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString)")
            }        }
    }
}

extension JSONDecoder {
    /// A default `JSONDecoder`.
    public static let `default`: JSONDecoder = stream
    
    /// A Stream Chat JSON decoder.
    static let stream: StreamJSONDecoder = {
        StreamJSONDecoder()
    }()
}

// MARK: - JSONEncoder Stream

extension JSONEncoder {
    /// A default `JSONEncoder`.
    public static let `default`: JSONEncoder = stream
    /// A default gzip `JSONEncoder`.
    static let defaultGzip: JSONEncoder = streamGzip
    
    /// A Stream Chat JSON encoder.
    static let stream: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .stream
        return encoder
    }()
    
    /// A Stream Chat JSON encoder with a gzipped content.
    static let streamGzip: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .gzip
        encoder.dateEncodingStrategy = .stream
        return encoder
    }()
}

extension JSONEncoder.DataEncodingStrategy {
    // Gzip data encoding.
    static var gzip: JSONEncoder.DataEncodingStrategy {
        .custom { data, encoder throws in
            var container = encoder.singleValueContainer()
            let gzippedData = try data.gzipped()
            try container.encode(gzippedData)
        }
    }
}

extension JSONEncoder.DateEncodingStrategy {
    /// A Stream encoding for the custom ISO8601 date.
    static var stream: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder throws in
            var container = encoder.singleValueContainer()
            try container.encode(DateFormatter.Stream.rfc3339DateString(from: date))
        }
    }
}

// MARK: - Date Formatter Helper

extension DateFormatter {
    /// Stream Chat date formatters.
    enum Stream {
        // Creates and returns a date object from the specified RFC3339 formatted string representation.
        ///
        /// - Parameter string: The RFC3339 formatted string representation of a date.
        /// - Returns: A date object, or nil if no valid date was found.
        static func rfc3339Date(from string: String) -> Date? {
            let RFC3339TimezoneWrapper = "Z"
            let uppercaseString = string.uppercased()
            let removedTimezoneWrapperString = uppercaseString.replacingOccurrences(of: RFC3339TimezoneWrapper, with: "-0000")
            return gmtDateFormatters.lazy.compactMap { $0.date(from: removedTimezoneWrapperString) }.first
        }
        
        /// Creates and returns an RFC 3339 formatted string representation of the specified date.
        ///
        /// - Parameter date: The date to be represented.
        /// - Returns: A user-readable string representing the date.
        static func rfc3339DateString(from date: Date) -> String? {
            let nanosecondsInMillisecond = 1_000_000
            
            var gmtCalendar = Calendar(identifier: .iso8601)
            if let zeroTimezone = TimeZone(secondsFromGMT: 0) {
                gmtCalendar.timeZone = zeroTimezone
            }
            
            let components = gmtCalendar.dateComponents([.nanosecond], from: date)
            // If nanoseconds is more that 1 millisecond, use format with fractional seconds
            guard let nanoseconds = components.nanosecond,
                  nanoseconds >= nanosecondsInMillisecond
            else {
                return dateFormatterWithoutFractional.string(from: date)
            }
            
            return dateFormatterWithFractional.string(from: date)
        }
        
        // Formats according to samples
        // 2000-12-19T16:39:57-0800
        // 1934-01-01T12:00:27.87+0020
        // 1989-01-01T12:00:27
        private static let gmtDateFormatters: [DateFormatter] = [
            "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ",
            "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ",
            "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
        ].map(makeDateFormatter)
        
        private static let dateFormatterWithoutFractional = makeDateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
        private static let dateFormatterWithFractional = makeDateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX")
        
        private static func makeDateFormatter(dateFormat: String) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = dateFormat
            return formatter
        }
    }
}

typealias DBDate = NSDate
extension DBDate {
    var bridgeDate: Date {
        Date(timeIntervalSince1970: timeIntervalSince1970)
    }
}

extension Date {
    var bridgeDate: DBDate {
        DBDate(timeIntervalSince1970: timeIntervalSince1970)
    }
}

extension ClientError {
    public class UnsupportedEventType: ClientError, @unchecked Sendable {
        override public var localizedDescription: String { "The incoming event type is not supported. Ignoring." }
    }
    
    public class EventDecoding: ClientError, @unchecked Sendable {
        override init(_ message: String, _ file: StaticString = #fileID, _ line: UInt = #line) {
            super.init(message, file, line)
        }
        
        init<T>(missingValue: String, for type: T.Type, _ file: StaticString = #fileID, _ line: UInt = #line) {
            super.init("`\(missingValue)` field can't be `nil` for the `\(type)` event.", file, line)
        }
    }
}
