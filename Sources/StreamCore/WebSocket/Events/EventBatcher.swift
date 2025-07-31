//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type that does events batching.
protocol EventBatcher: Sendable {
    typealias Batch = [Event]
    typealias BatchHandler = @Sendable (_ batch: Batch, _ completion: @Sendable @escaping () -> Void) -> Void

    /// The current batch of events.
    var currentBatch: Batch { get }
    
    /// Creates new batch processor.
    init(period: TimeInterval, timerType: Timer.Type, handler: @escaping BatchHandler)

    /// Adds the item to the current batch of events. If it's the first event also schedules batch processing
    /// that will happen when `period` has passed.
    ///
    /// - Parameter event: The event to add to the current batch.
    func append(_ event: Event)
    
    /// Ignores `period` and passes the current batch of events to handler as soon as possible.
    func processImmediately(completion: @Sendable @escaping () -> Void)
}

class Batcher<Item>: @unchecked Sendable {
    /// The batching period. If the item is added sonner then `period` has passed after the first item they will get into the same batch.
    private let period: TimeInterval
    /// The time used to create timers.
    private let timerType: Timer.Type
    /// The timer that  calls `processor` when fired.
    private let batchProcessingTimer = AllocatedUnfairLock<TimerControl?>(nil)
    /// The closure which processes the batch.
    private let handler: @Sendable (_ batch: [Item], _ completion: @Sendable @escaping () -> Void) -> Void
    /// The serial queue where item appends and batch processing is happening on.
    private let queue = DispatchQueue(label: "io.getstream.Batch.\(Item.self)")
    /// The current batch of items.
    let currentBatch = AllocatedUnfairLock([Item]())
    
    init(
        period: TimeInterval,
        timerType: Timer.Type = DefaultTimer.self,
        handler: @Sendable @escaping (_ batch: [Item], _ completion: @Sendable @escaping () -> Void) -> Void
    ) {
        self.period = max(period, 0)
        self.timerType = timerType
        self.handler = handler
    }
    
    func append(_ item: Item) {
        timerType.schedule(timeInterval: 0, queue: queue) { [weak self] in
            self?.currentBatch.withLock { $0.append(item) }
            
            guard let self, batchProcessingTimer.value == nil else { return }
            
            batchProcessingTimer.value = timerType.schedule(
                timeInterval: period,
                queue: queue,
                onFire: { self.process() }
            )
        }
    }
    
    func processImmediately(completion: @Sendable @escaping () -> Void) {
        timerType.schedule(timeInterval: 0, queue: queue) { [weak self] in
            self?.process(completion: completion)
        }
    }
    
    private func process(completion: (@Sendable () -> Void)? = nil) {
        let items = currentBatch.withLock { items in
            let existingItems = items
            items.removeAll()
            return existingItems
        }
        handler(items) { completion?() }
        batchProcessingTimer.withLock { timer in
            timer?.cancel()
            timer = nil
        }
    }
}
