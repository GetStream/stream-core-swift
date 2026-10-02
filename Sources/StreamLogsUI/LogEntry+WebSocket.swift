//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct LogWebSocketMessage: Equatable, Sendable {
    enum Direction: Equatable, Sendable {
        case received
        case sent
    }

    let direction: Direction
    let eventType: String?
    let payloadKey: LogEntry.MetadataKey
    let payload: String
}

extension LogEntry {
    var webSocketMessage: LogWebSocketMessage? {
        let eventType = metadata[.webSocketEventType]
        if let payload = metadata[.webSocketReceivedPayload] {
            return LogWebSocketMessage(direction: .received, eventType: eventType, payloadKey: .webSocketReceivedPayload, payload: payload)
        }
        if let payload = metadata[.webSocketSentPayload] {
            return LogWebSocketMessage(direction: .sent, eventType: eventType, payloadKey: .webSocketSentPayload, payload: payload)
        }
        return nil
    }
}
