//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The key of a value attached to a log message, like the URL of an HTTP request.
///
/// Destinations inheriting from ``BaseLogDestination`` print the metadata after the message, one `Key: value` per line,
/// so raw values are meant to be read by people.
public struct LogMetadataKey: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension LogMetadataKey {
    /// The method of an HTTP request, like `POST`.
    static let httpMethod: LogMetadataKey = "Method"
    /// The URL of an HTTP request.
    static let httpURL: LogMetadataKey = "URL"
    /// The status code of an HTTP response, like `200`.
    static let httpStatusCode: LogMetadataKey = "Status Code"
    /// The error of a failed HTTP request, like a connection error.
    static let httpError: LogMetadataKey = "Error"
    /// The body of an HTTP request.
    static let httpRequestBody: LogMetadataKey = "Request Body"
    /// The body of an HTTP response.
    static let httpResponseBody: LogMetadataKey = "Response Body"
    /// A cURL command that reproduces an HTTP request.
    static let httpCURL: LogMetadataKey = "cURL"
    /// The type of a WebSocket event, like `message.new`.
    static let webSocketEventType: LogMetadataKey = "Event Type"
    /// The payload of a message received through a WebSocket.
    static let webSocketReceivedPayload: LogMetadataKey = "Received Payload"
    /// The payload of a message sent through a WebSocket.
    static let webSocketSentPayload: LogMetadataKey = "Sent Payload"
}

extension LogDetails {
    // Predefined keys come first, in a fixed order, followed by the other keys sorted by name.
    private static let metadataOrder: [LogMetadataKey] = [
        .httpMethod, .httpURL, .httpStatusCode, .httpError, .httpRequestBody, .httpResponseBody, .httpCURL,
        .webSocketEventType, .webSocketReceivedPayload, .webSocketSentPayload
    ]

    var messageWithMetadata: String {
        guard !metadata.isEmpty else { return message }
        let rank = { (key: LogMetadataKey) in Self.metadataOrder.firstIndex(of: key) ?? Self.metadataOrder.count }
        let lines = metadata
            .sorted { lhs, rhs in
                let lhsRank = rank(lhs.key)
                let rhsRank = rank(rhs.key)
                return lhsRank == rhsRank ? lhs.key.rawValue < rhs.key.rawValue : lhsRank < rhsRank
            }
            .map { key, value in
                value.contains("\n") ? "\(key.rawValue):\n\(value)" : "\(key.rawValue): \(value)"
            }
        return ([message] + lines).joined(separator: "\n")
    }
}
