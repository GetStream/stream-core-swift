//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A value attached to a log message, like an HTTP request, that log destinations can display in more detail.
///
/// Destinations inheriting from ``BaseLogDestination`` print its ``logDescription`` after the message.
public protocol LogAttachment: Sendable {
    /// The description printed after the message, meant to be read by people.
    var logDescription: String { get }
}

/// An HTTP request attached to a log message, with its response or error.
public struct HTTPLogAttachment: LogAttachment {
    /// The request that was sent.
    public let request: URLRequest
    /// The response that was received, if any.
    public let response: URLResponse?
    /// The body of the response, if any.
    public let responseBody: Data?
    /// The error the request failed with, if any.
    public let error: Error?
    /// The session that sent the request, whose additional headers were sent with it.
    public let session: URLSession?

    /// Creates the attachment of an HTTP request, with its response or error when it completed.
    public init(
        request: URLRequest,
        response: URLResponse? = nil,
        responseBody: Data? = nil,
        error: Error? = nil,
        session: URLSession? = nil
    ) {
        self.request = request
        self.response = response
        self.responseBody = responseBody
        self.error = error
        self.session = session
    }

    public var logDescription: String {
        var lines = ["cURL:\n\(request.cURLRepresentation(in: session))"]
        if let error {
            lines.append("Error: \(error)")
        }
        if let requestBody = request.httpBody?.logDescription {
            lines.append("Request Body:\n\(requestBody)")
        }
        if let responseBody = responseBody?.logDescription {
            lines.append("Response Body:\n\(responseBody)")
        }
        return lines.joined(separator: "\n")
    }
}

/// A message sent or received through a WebSocket, attached to a log message.
public struct WebSocketLogAttachment: LogAttachment {
    /// Whether a WebSocket message was sent or received.
    public enum Direction: Sendable {
        case sent
        case received
    }

    /// Whether the message was sent or received.
    public let direction: Direction
    /// The payload of the message.
    public let payload: Data

    /// Creates the attachment of a WebSocket message.
    public init(direction: Direction, payload: Data) {
        self.direction = direction
        self.payload = payload
    }

    public var logDescription: String {
        payload.logDescription ?? "<\(payload.count) bytes>"
    }
}

extension LogDetails {
    var messageWithAttachment: String {
        guard let attachment else { return message }
        return "\(message)\n\(attachment.logDescription)"
    }
}

extension Data {
    // Pretty-printed JSON, or the text of other data, or `nil` when the data is empty or isn't text.
    var logDescription: String? {
        guard !isEmpty else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: self, options: .fragmentsAllowed),
              let json = try? JSONSerialization.data(
                  withJSONObject: object,
                  options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]
              ) else {
            return String(data: self, encoding: .utf8)
        }
        return String(decoding: json, as: UTF8.self)
    }
}
