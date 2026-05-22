//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamCore
import XCTest

/// Regression tests for the data race between `DefaultConnectionRecoveryHandler` and the WebSocket
/// engine queue. See plan file `quizzical-jumping-bunny.md` for the full bug analysis.
///
/// The bug: `disconnectIfNeeded()` performs a check-then-act on `webSocketClient.connectionState`.
/// Without the fix, the check runs on the caller's queue (typically `io.getstream.internet-monitor`)
/// and `disconnect(...)` writes `.disconnecting` from that same queue. The engine queue can
/// independently write `.disconnected` between the check and the write, after which the handler's
/// stale write overwrites the legitimate `.disconnected`. The engine then never re-fires
/// `webSocketDidDisconnect`, so state stays stuck at `.disconnecting`.
///
/// The fix wraps `disconnectIfNeeded` and `reconnectIfNeeded` in `webSocketClient.engineQueue.async`,
/// serializing the handler's check-and-act with the engine's own state writes.
final class ConnectionRecoveryHandler_Tests: XCTestCase, @unchecked Sendable {
    private var webSocketClient: WebSocketClient!
    private var eventNotificationCenter: EventNotificationCenter_Mock!
    private var internetMonitor: InternetConnectionMonitor_Mock!
    private var internetConnection: InternetConnection!
    private var handler: DefaultConnectionRecoveryHandler!
    private var time: VirtualTime!

    private let healthCheckInfo = HealthCheckInfo(connectionId: "test-connection-id")

    override func setUp() {
        super.setUp()

        time = VirtualTime()
        VirtualTimeTimer.time = time

        eventNotificationCenter = EventNotificationCenter_Mock()

        var environment = WebSocketClient.Environment.mock
        environment.timerType = VirtualTimeTimer.self

        webSocketClient = WebSocketClient(
            sessionConfiguration: .ephemeral,
            eventDecoder: EventDecoder_Mock(),
            eventNotificationCenter: eventNotificationCenter,
            webSocketClientType: .coordinator,
            environment: environment,
            connectRequest: URLRequest(url: URL(string: "http://example.com/ws")!)
        )

        // Use an isolated NotificationCenter so tests don't observe each other.
        internetMonitor = InternetConnectionMonitor_Mock()
        internetConnection = InternetConnection(
            notificationCenter: NotificationCenter(),
            monitor: internetMonitor
        )

        handler = DefaultConnectionRecoveryHandler(
            webSocketClient: webSocketClient,
            eventNotificationCenter: eventNotificationCenter,
            backgroundTaskScheduler: nil,
            internetConnection: internetConnection,
            reconnectionStrategy: DefaultRetryStrategy(),
            reconnectionTimerType: VirtualTimeTimer.self,
            keepConnectionAliveInBackground: false
        )
    }

    override func tearDown() {
        handler?.stop()
        handler = nil
        internetConnection = nil
        internetMonitor = nil
        webSocketClient = nil
        eventNotificationCenter = nil
        VirtualTimeTimer.invalidate()
        time = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Posts `.internetConnectionAvailabilityDidChange` synchronously from `queue` and waits for the
    /// observer chain to drain. The handler's `@objc` selector runs on `queue` because the observer
    /// was registered without an explicit `OperationQueue`.
    private func postInternetAvailability(_ status: InternetConnectionStatus, from queue: DispatchQueue) {
        let posted = expectation(description: "notification posted on \(queue.label)")
        queue.async { [internetConnection] in
            internetConnection!.notificationCenter.post(
                name: .internetConnectionAvailabilityDidChange,
                object: internetConnection,
                userInfo: [Notification.internetConnectionStatusUserInfoKey: status]
            )
            posted.fulfill()
        }
        wait(for: [posted], timeout: 1)
    }

    /// Enqueues a no-op block on `engineQueue` and waits for it to run, ensuring all previously
    /// queued work has completed.
    private func drainEngineQueue() {
        let drained = expectation(description: "engineQueue drained")
        webSocketClient.engineQueue.async { drained.fulfill() }
        wait(for: [drained], timeout: 2)
    }

    // MARK: - Test 1: disconnectIfNeeded must dispatch onto engineQueue

    /// Verifies the fix's mechanism. When the internet-down notification arrives on a non-engine
    /// queue, the handler must NOT write to `connectionState` synchronously from that queue.
    ///
    /// Without the fix this assertion fails: the handler runs `canBeDisconnected` synchronously,
    /// then calls `webSocketClient.disconnect(source: .systemInitiated)`, which writes
    /// `.disconnecting` on the internet-monitor queue immediately. We observe that write as soon
    /// as `post()` returns. With the fix, the handler's block is queued onto the suspended
    /// `engineQueue`, so state is still `.connected` at the moment of assertion.
    func test_disconnectIfNeeded_dispatchesOntoEngineQueue() {
        webSocketClient.connectionState = .connected(healthCheckInfo: healthCheckInfo)

        webSocketClient.engineQueue.suspend()
        defer { webSocketClient.engineQueue.resume() }

        let internetMonitorQueue = DispatchQueue(label: "test.internet-monitor")
        postInternetAvailability(.unavailable, from: internetMonitorQueue)

        XCTAssertEqual(
            webSocketClient.connectionState,
            .connected(healthCheckInfo: healthCheckInfo),
            "Handler must not mutate connectionState on the caller's queue; it must dispatch onto engineQueue."
        )
    }

    // MARK: - Test 2: real race — concurrent engine fire + internet-down never sticks at .disconnecting

    /// Real-world race shape. Runs many iterations of: `webSocketDidDisconnect` on `engineQueue`
    /// concurrent with the internet-down notification on a separate queue. With the fix, state
    /// always ends at `.disconnected`. Without the fix, some iterations may end at `.disconnecting`
    /// when the threads interleave as:
    ///
    ///   1. handler's `canBeDisconnected` reads `.connected`
    ///   2. engine's `webSocketDidDisconnect` writes `.disconnected`
    ///   3. handler's `disconnect()` writes `.disconnecting`
    ///
    /// — and no further engine callback fires to recover.
    ///
    /// Note: this is a best-effort stress test. The race window between handler's check and act
    /// is narrow (a few CPU instructions plus a log statement), so the bug may not reproduce
    /// reliably on every machine. Tests 1 and 3 are the authoritative regression checks; this
    /// test gives additional confidence under load.
    func test_concurrentEngineDisconnectAndInternetDown_neverStucksAtDisconnecting() {
        let iterations = 2000

        for iteration in 0..<iterations {
            webSocketClient.connectionState = .connected(healthCheckInfo: healthCheckInfo)

            let internetMonitorQueue = DispatchQueue(label: "test.internet-monitor.\(iteration)")
            let group = DispatchGroup()

            // Pre-queue the engine's webSocketDidDisconnect onto engineQueue (without barrier) so
            // it starts as soon as possible. Then post the notification on a separate queue.
            // Letting both run without a barrier increases the chance their orderings interleave
            // through all three race positions across iterations.
            group.enter()
            webSocketClient.engineQueue.async { [webSocketClient] in
                webSocketClient!.webSocketDidDisconnect(error: nil)
                group.leave()
            }

            group.enter()
            internetMonitorQueue.async { [internetConnection] in
                internetConnection!.notificationCenter.post(
                    name: .internetConnectionAvailabilityDidChange,
                    object: internetConnection,
                    userInfo: [Notification.internetConnectionStatusUserInfoKey: InternetConnectionStatus.unavailable]
                )
                group.leave()
            }

            let bothDone = expectation(description: "both threads done iter \(iteration)")
            group.notify(queue: .global()) { bothDone.fulfill() }
            wait(for: [bothDone], timeout: 2)

            drainEngineQueue()

            if case .disconnecting = webSocketClient.connectionState {
                XCTFail(
                    "Iteration \(iteration): connectionState stuck at \(webSocketClient.connectionState). " +
                        "The handler's call to disconnect() overwrote the engine's .disconnected write."
                )
                return
            }
        }
    }

    // MARK: - Test 3: reconnectIfNeeded must dispatch onto engineQueue (symmetric)

    /// Symmetric to Test 1 but for the reconnect path. When state is `.disconnected` and the
    /// internet returns, the handler must NOT write `.connecting` synchronously from the
    /// internet-monitor queue. It must dispatch onto `engineQueue`.
    func test_reconnectIfNeeded_dispatchesOntoEngineQueue() {
        webSocketClient.connectionState = .disconnected(source: .serverInitiated(error: nil))

        // Make the internet availability policy return true.
        internetMonitor.status = .available(.great)

        webSocketClient.engineQueue.suspend()
        defer { webSocketClient.engineQueue.resume() }

        let internetMonitorQueue = DispatchQueue(label: "test.internet-monitor")
        postInternetAvailability(.available(.great), from: internetMonitorQueue)

        XCTAssertEqual(
            webSocketClient.connectionState,
            .disconnected(source: .serverInitiated(error: nil)),
            "Handler must not mutate connectionState on the caller's queue for reconnect; it must dispatch onto engineQueue."
        )
    }
}
