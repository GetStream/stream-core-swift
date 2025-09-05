//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore

final class EventBatcher_Mock: Batcher<Event>, @unchecked Sendable {
    let handler: @Sendable (_ batch: [Event], _ completion: @escaping @Sendable () -> Void) -> Void

    override init(
        period: TimeInterval = 0,
        timerType: StreamCore.Timer.Type = DefaultTimer.self,
        handler: @escaping @Sendable (_ batch: [Event], _ completion: @escaping @Sendable () -> Void) -> Void
    ) {
        self.handler = handler
        super.init(period: period, timerType: timerType, handler: handler)
    }

    lazy var mock_append = MockFunc.mock(for: append)

    override func append(_ event: Event) {
        mock_append.call(with: (event))

        handler([event]) {}
    }

    lazy var mock_processImmediately = MockFunc.mock(for: processImmediately)

    override func processImmediately(completion: @escaping () -> Void) {
        mock_processImmediately.call(with: (completion))
    }
}
