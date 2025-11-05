//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
public protocol EventNotificationCenter: NotificationCenter, Sendable {
    func process(_ events: [Event], postNotifications: Bool, completion: (@Sendable () -> Void)?)
}

public extension EventNotificationCenter {
    func process(
        _ event: Event,
        postNotification: Bool = true,
        completion: (@Sendable () -> Void)? = nil
    ) {
        process([event], postNotifications: postNotification, completion: completion)
    }
}

/// The type is designed to pre-process some incoming `Event` via middlewares before being published
public class DefaultEventNotificationCenter: NotificationCenter, EventNotificationCenter, @unchecked Sendable {
    private(set) var middlewares: [EventMiddleware] = []

    var eventPostingQueue = DispatchQueue(label: "io.getstream.event-notification-center")
    
    public func add(middlewares: [EventMiddleware]) {
        self.middlewares.append(contentsOf: middlewares)
    }

    func add(middleware: EventMiddleware) {
        middlewares.append(middleware)
    }

    public func process(
        _ events: [Event],
        postNotifications: Bool = true,
        completion: (@Sendable () -> Void)? = nil
    ) {
        let processingEventsDebugMessage: () -> String = {
            let eventNames = events.map(\.name)
            return "Processing webSocket events: \(eventNames)"
        }
        log.debug(processingEventsDebugMessage(), subsystems: .webSocket)

        let eventsToPost = events.compactMap {
            self.middlewares.process(event: $0)
        }
        
        guard postNotifications else {
            completion?()
            return
        }

        eventPostingQueue.async {
            eventsToPost.forEach { self.post(Notification(newEventReceived: $0, sender: self)) }
            completion?()
        }
    }
}

public extension EventNotificationCenter {
    func subscribe<E>(
        to event: E.Type,
        filter: @escaping (E) -> Bool = { _ in true },
        handler: @escaping (E) -> Void
    ) -> AnyCancellable where E: Event {
        publisher(for: .NewEventReceived)
            .compactMap { $0.event as? E }
            .filter(filter)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }

    func subscribe(
        filter: @escaping (Event) -> Bool = { _ in true },
        handler: @escaping (Event) -> Void
    ) -> AnyCancellable {
        publisher(for: .NewEventReceived)
            .compactMap(\.event)
            .filter(filter)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
    }
}
