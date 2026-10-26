//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamCore
import XCTest

final class TimerPublisher_Tests: XCTestCase, @unchecked Sendable {
    private var subscriber: DemandSubscriber! = DemandSubscriber()

    override func tearDown() {
        subscriber.cancel()
        subscriber = nil
        super.tearDown()
    }

    func test_publish_whenSubscriberRequestsOne_deliversOnlyOneValue() {
        let first = expectation(description: "First value")
        let second = expectation(description: "No second value")
        second.isInverted = true
        subscriber.onValue = { count in count == 1 ? first.fulfill() : second.fulfill() }

        DefaultTimer.publish(every: 0.05).subscribe(subscriber)
        subscriber.request(.max(1))

        wait(for: [first], timeout: 2)
        wait(for: [second], timeout: 0.5)
        XCTAssertEqual(subscriber.values.count, 1)
    }

    func test_publish_whenReceiveReturnsDemand_continuesDelivery() {
        let third = expectation(description: "Third value")
        subscriber.demandPerValue = .max(1)
        subscriber.onValue = { count in if count == 3 { third.fulfill() } }

        DefaultTimer.publish(every: 0.05).subscribe(subscriber)
        subscriber.request(.max(1))

        wait(for: [third], timeout: 2)
    }

    func test_publish_whenDemandRequestedLater_resumesDelivery() {
        let first = expectation(description: "First value")
        let second = expectation(description: "Second value")
        subscriber.onValue = { count in count == 1 ? first.fulfill() : second.fulfill() }

        DefaultTimer.publish(every: 0.05).subscribe(subscriber)
        subscriber.request(.max(1))
        wait(for: [first], timeout: 2)

        subscriber.request(.max(1))
        wait(for: [second], timeout: 2)
        XCTAssertEqual(subscriber.values.count, 2)
    }

    func test_publish_whenCancelled_stopsDelivery() {
        let first = expectation(description: "First value")
        let second = expectation(description: "No value after cancel")
        second.isInverted = true
        subscriber.onValue = { count in count == 1 ? first.fulfill() : second.fulfill() }

        DefaultTimer.publish(every: 0.05).subscribe(subscriber)
        subscriber.request(.unlimited)
        wait(for: [first], timeout: 2)

        subscriber.cancel()
        wait(for: [second], timeout: 0.5)
    }

    func test_publish_whenDemandIsUnlimited_deliversRepeatedly() {
        let third = expectation(description: "Third value")
        subscriber.onValue = { count in if count == 3 { third.fulfill() } }

        DefaultTimer.publish(every: 0.05).subscribe(subscriber)
        subscriber.request(.unlimited)

        wait(for: [third], timeout: 2)
    }
}

private final class DemandSubscriber: Subscriber, @unchecked Sendable {
    typealias Input = Date
    typealias Failure = Never

    var demandPerValue: Subscribers.Demand = .none
    var onValue: ((Int) -> Void)?
    private(set) var values: [Date] = []
    private let lock = NSLock()
    private var subscription: Subscription?

    func receive(subscription: Subscription) {
        self.subscription = subscription
    }

    func receive(_ input: Date) -> Subscribers.Demand {
        lock.lock()
        values.append(input)
        let count = values.count
        lock.unlock()
        onValue?(count)
        return demandPerValue
    }

    func receive(completion: Subscribers.Completion<Never>) {}

    func request(_ demand: Subscribers.Demand) {
        subscription?.request(demand)
    }

    func cancel() {
        subscription?.cancel()
        subscription = nil
    }
}
