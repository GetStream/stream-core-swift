//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event: Sendable {}

extension Event {
    func healthcheck() -> HealthCheckInfo? {
        return nil
    }
    
    func error() -> Error? {
        return nil
    }
}

public protocol SendableEvent: Event, ReflectiveStringConvertible {
    func serializedData(partial: Bool) throws -> Data
}

extension Event {
    var name: String {
        String(describing: Self.self)
    }
}

/// A type-erased wrapper protocol for `EventDecoder`.
protocol AnyEventDecoder {
    func decode(from: Data) throws -> Event
}

struct HealthCheckInfo: Equatable {
    let connectionId: String?
    let participantCount: Int?
}
