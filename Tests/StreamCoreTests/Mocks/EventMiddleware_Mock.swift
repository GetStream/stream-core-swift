//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore

/// A test middleware that can be initiated with a closure
final class EventMiddleware_Mock: EventMiddleware, @unchecked Sendable {
    var closure: (Event) -> Event?

    init(closure: @escaping (Event) -> Event? = { event in event }) {
        self.closure = closure
    }

    func handle(event: Event) -> Event? {
        closure(event)
    }
}
