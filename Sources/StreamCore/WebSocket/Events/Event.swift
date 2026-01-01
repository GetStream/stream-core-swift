//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event: Sendable {
    func healthcheck() -> HealthCheckInfo?
    func error() -> Error?
}

public extension Event {
    func healthcheck() -> HealthCheckInfo? {
        nil
    }
    
    func error() -> Error? {
        nil
    }
}

public protocol SendableEvent: Event {
    func serializedData(partial: Bool) throws -> Data
}

extension Event {
    public var name: String {
        String(describing: Self.self)
    }
}

/// A type-erased wrapper protocol for `EventDecoder`.
public protocol AnyEventDecoder {
    func decode(from: Data) throws -> Event
}

public struct HealthCheckInfo: Equatable, Sendable {
    public let connectionId: String?
    public let participantCount: Int?
    
    public init(connectionId: String? = nil, participantCount: Int? = nil) {
        self.connectionId = connectionId
        self.participantCount = participantCount
    }
}
