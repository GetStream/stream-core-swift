//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamCore
import XCTest

final class DisposableBag_Tests: XCTestCase, @unchecked Sendable {
    func test_completed_removesCancellableWithoutCancelling() {
        let subject = DisposableBag()
        var wasCancelled = false
        let cancellable = AnyCancellable { wasCancelled = true }

        subject.insert(cancellable, with: "task")
        subject.completed("task")

        XCTAssertTrue(subject.isEmpty)
        XCTAssertFalse(wasCancelled)
        withExtendedLifetime(cancellable) {}
    }

    func test_remove_removesAndCancelsCancellable() {
        let subject = DisposableBag()
        var wasCancelled = false
        let cancellable = AnyCancellable { wasCancelled = true }

        subject.insert(cancellable, with: "task")
        subject.remove("task")

        XCTAssertTrue(subject.isEmpty)
        XCTAssertTrue(wasCancelled)
        withExtendedLifetime(cancellable) {}
    }
}
