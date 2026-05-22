//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// The type that keeps track of active chat components and asks them to reconnect when it's needed
public protocol ConnectionRecoveryHandler: ConnectionStateDelegate, Sendable {
    func start()
    func stop()
}

/// The type is designed to obtain missing events that happened in watched channels while user
/// was not connected to the web-socket.
///
/// When the status becomes `connected` the `/sync` endpoint is called
/// with `lastReceivedEventDate` and `cids` of watched channels.
///
/// We remember `lastReceivedEventDate` when state becomes `connecting` to catch the last event date
/// before the `HealthCheck` override the `lastReceivedEventDate` with the recent date.
///
public final class DefaultConnectionRecoveryHandler: ConnectionRecoveryHandler, @unchecked Sendable {
    // MARK: - Properties
    
    private let webSocketClient: WebSocketClient
    private let eventNotificationCenter: EventNotificationCenter
    private let backgroundTaskScheduler: BackgroundTaskScheduler?
    private let internetConnection: InternetConnection
    private let reconnectionTimerType: TimerScheduling.Type
    private let keepConnectionAliveInBackground: Bool
    private nonisolated(unsafe) var reconnectionStrategy: RetryStrategy
    private nonisolated(unsafe) var reconnectionTimer: TimerControl?
    private nonisolated(unsafe) var reconnectionPolicies: [AutomaticReconnectionPolicy]

    // MARK: - Init

    public convenience init(
        webSocketClient: WebSocketClient,
        eventNotificationCenter: EventNotificationCenter,
        backgroundTaskScheduler: BackgroundTaskScheduler?,
        internetConnection: InternetConnection,
        reconnectionStrategy: RetryStrategy,
        reconnectionTimerType: TimerScheduling.Type,
        keepConnectionAliveInBackground: Bool
    ) {
        self.init(
            webSocketClient: webSocketClient,
            eventNotificationCenter: eventNotificationCenter,
            backgroundTaskScheduler: backgroundTaskScheduler,
            internetConnection: internetConnection,
            reconnectionStrategy: reconnectionStrategy,
            reconnectionTimerType: reconnectionTimerType,
            keepConnectionAliveInBackground: keepConnectionAliveInBackground,
            reconnectionPolicies: [
                WebSocketAutomaticReconnectionPolicy(webSocketClient),
                InternetAvailabilityReconnectionPolicy(internetConnection),
                BackgroundStateReconnectionPolicy(backgroundTaskScheduler)
            ]
        )
    }

    public init(
        webSocketClient: WebSocketClient,
        eventNotificationCenter: EventNotificationCenter,
        backgroundTaskScheduler: BackgroundTaskScheduler?,
        internetConnection: InternetConnection,
        reconnectionStrategy: RetryStrategy,
        reconnectionTimerType: TimerScheduling.Type,
        keepConnectionAliveInBackground: Bool,
        reconnectionPolicies: [AutomaticReconnectionPolicy]
    ) {
        self.webSocketClient = webSocketClient
        self.eventNotificationCenter = eventNotificationCenter
        self.backgroundTaskScheduler = backgroundTaskScheduler
        self.internetConnection = internetConnection
        self.reconnectionStrategy = reconnectionStrategy
        self.reconnectionTimerType = reconnectionTimerType
        self.keepConnectionAliveInBackground = keepConnectionAliveInBackground
        self.reconnectionPolicies = reconnectionPolicies

        start()
    }
    
    public func start() {
        subscribeOnNotifications()
    }

    public func stop() {
        unsubscribeFromNotifications()
        cancelReconnectionTimer()
    }

    deinit {
        stop()
    }
}

// MARK: - Subscriptions

private extension DefaultConnectionRecoveryHandler {
    func subscribeOnNotifications() {
        backgroundTaskScheduler?.startListeningForAppStateUpdates(
            onEnteringBackground: { [weak self] in self?.appDidEnterBackground() },
            onEnteringForeground: { [weak self] in self?.appDidBecomeActive() }
        )
        
        internetConnection.notificationCenter.addObserver(
            self,
            selector: #selector(internetConnectionAvailabilityDidChange(_:)),
            name: .internetConnectionAvailabilityDidChange,
            object: nil
        )
    }
    
    func unsubscribeFromNotifications() {
        backgroundTaskScheduler?.stopListeningForAppStateUpdates()
        internetConnection.notificationCenter.removeObserver(
            self,
            name: .internetConnectionStatusDidChange,
            object: nil
        )
    }
}

// MARK: - Event handlers

extension DefaultConnectionRecoveryHandler {
    private func appDidBecomeActive() {
        log.debug("App -> ✅", subsystems: .webSocket)
        
        backgroundTaskScheduler?.endTask()
        
        reconnectIfNeeded()
    }
    
    private func appDidEnterBackground() {
        log.debug("App -> 💤", subsystems: .webSocket)
        
        guard canBeDisconnected else {
            // Client is not trying to connect nor connected
            return
        }
        
        guard keepConnectionAliveInBackground else {
            // We immediately disconnect
            disconnectIfNeeded()
            return
        }
        
        guard let scheduler = backgroundTaskScheduler else { return }
        
        let succeed = scheduler.beginTask { [weak self] in
            log.debug("Background task -> ❌", subsystems: .webSocket)
            
            self?.disconnectIfNeeded()
        }
        
        if succeed {
            log.debug("Background task -> ✅", subsystems: .webSocket)
        } else {
            // Can't initiate a background task, close the connection
            disconnectIfNeeded()
        }
    }
    
    @objc private func internetConnectionAvailabilityDidChange(_ notification: Notification) {
        guard let isAvailable = notification.internetConnectionStatus?.isAvailable else { return }
        
        log.debug("Internet -> \(isAvailable ? "✅" : "❌")", subsystems: .webSocket)
        
        if isAvailable {
            reconnectIfNeeded()
        } else {
            disconnectIfNeeded()
        }
    }
    
    public func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState) {
        log.debug("Connection state: \(state)", subsystems: .webSocket)
        
        switch state {
        case .connecting:
            cancelReconnectionTimer()
        case .connected:
            reconnectionStrategy.resetConsecutiveFailures()
        case .disconnected:
            scheduleReconnectionTimerIfNeeded()
        case .initialized, .authenticating, .disconnecting:
            break
        }
    }
}

// MARK: - Disconnection

private extension DefaultConnectionRecoveryHandler {
    /// Asks the web socket client to disconnect when the system decides we should drop the connection
    /// (app went to background, internet became unavailable, background task expired, etc.).
    ///
    /// The work is dispatched onto `WebSocketClient.engineQueue` to serialize the check-and-act
    /// (`canBeDisconnected` read + `webSocketClient.disconnect(...)` call) against the engine's
    /// own state mutations. All `WebSocketEngineDelegate` callbacks — `webSocketDidConnect`,
    /// `webSocketDidReceiveMessage`, `webSocketDidDisconnect` — run on `engineQueue` and mutate
    /// `WebSocketClient.connectionState`. By piggy-backing on the same serial queue, our decision
    /// cannot interleave with theirs.
    ///
    /// Bug this prevents: this method is called from multiple queues (main thread for app lifecycle
    /// events, `io.getstream.internet-monitor` for reachability changes). Previously the flow was:
    ///
    ///   1. `canBeDisconnected` reads `connectionState == .connected` on the internet-monitor queue → returns `true`.
    ///   2. Meanwhile on `engineQueue`, `webSocketDidDisconnect` fires (Wi-Fi just dropped) and sets state to
    ///      `.disconnected(.serverInitiated)`.
    ///   3. The internet-monitor queue resumes and unconditionally calls `disconnect(source: .systemInitiated)`,
    ///      which writes `.disconnecting(.systemInitiated)`, overwriting the legitimate `.disconnected`.
    ///   4. The engine has already closed the socket, so no further `webSocketDidDisconnect` fires to
    ///      transition `.disconnecting → .disconnected`. State stays stuck at `.disconnecting`.
    ///   5. When Wi-Fi returns, `WebSocketAutomaticReconnectionPolicy` rejects reconnection because
    ///      `isAutomaticReconnectionEnabled` only matches `.disconnected`. The client never recovers.
    ///
    /// With this dispatch, the two writers are serialized on the same queue:
    ///
    /// - If the engine's `webSocketDidDisconnect` runs **before** this block, we read `.disconnected`,
    ///   `canBeDisconnected` returns `false`, no `disconnect()` call is made.
    /// - If this block runs **before** the engine callback, we transition to `.disconnecting` and the
    ///   queued engine callback then matches the `.disconnecting` case in `WebSocketClient.webSocketDidDisconnect`
    ///   and transitions to `.disconnected(source: source)`, unblocking reconnection.
    ///
    /// Either ordering ends at `.disconnected` — no stuck `.disconnecting` state.
    ///
    /// `[weak self]` is used because the handler is owned by the chat/video client and may outlive
    /// any individual dispatch; we don't want to extend its lifetime past `stop()` / `deinit`.
    func disconnectIfNeeded() {
        webSocketClient.engineQueue.async { [weak self] in
            guard let self else { return }
            guard self.canBeDisconnected else { return }
            log.debug("\(self.webSocketClient.connectionState)", subsystems: .webSocket)
            self.webSocketClient.disconnect(source: .systemInitiated) {
                log.debug("Did disconnect automatically", subsystems: .webSocket)
            }
        }
    }
    
    var canBeDisconnected: Bool {
        let state = webSocketClient.connectionState
        
        switch state {
        case .connecting, .authenticating, .connected:
            log.debug("Will disconnect automatically from \(state) state", subsystems: .webSocket)
            
            return true
        default:
            log.debug("Disconnect is not needed in \(state) state", subsystems: .webSocket)
            
            return false
        }
    }
}

// MARK: - Reconnection

private extension DefaultConnectionRecoveryHandler {
    /// Asks the web socket client to reconnect when conditions allow it (app returned to foreground,
    /// internet became available, reconnection timer fired).
    ///
    /// Like `disconnectIfNeeded`, the work is dispatched onto `WebSocketClient.engineQueue` to
    /// serialize against the engine's own state mutations. `WebSocketClient.connect()` reads
    /// `connectionState` (to early-return when already `.connecting` / `.authenticating` / `.connected`)
    /// and writes `.connecting`. If that check-and-write raced with the engine's delegate callbacks
    /// on `engineQueue`, we could end up with the same kind of stale-state overwrite seen in the
    /// disconnect path (e.g. engine sets `.authenticating` after we've read `.connecting`, then we
    /// overwrite back to `.connecting`).
    ///
    /// Dispatching here also guarantees that `canReconnectAutomatically` — which reads
    /// `webSocketClient.connectionState` through the reconnection policies — sees the same state
    /// the engine sees when this block runs, with no possibility of a delegate callback mutating
    /// state between our read and the `connect()` call.
    ///
    /// Entry points (all hop onto `engineQueue` here):
    /// - `appDidBecomeActive` (main thread)
    /// - `internetConnectionAvailabilityDidChange` with `isAvailable == true` (`io.getstream.internet-monitor` queue)
    /// - `scheduleReconnectionTimer` fire (main thread)
    ///
    /// `[weak self]` for the same reason as in `disconnectIfNeeded`.
    func reconnectIfNeeded() {
        webSocketClient.engineQueue.async { [weak self] in
            guard let self else { return }
            guard self.canReconnectAutomatically else { return }
            self.webSocketClient.connect()
        }
    }
    
    var canReconnectAutomatically: Bool {
        reconnectionPolicies.first { $0.canBeReconnected() == false } == nil
    }
}

// MARK: - Reconnection Timer

private extension DefaultConnectionRecoveryHandler {
    func scheduleReconnectionTimerIfNeeded() {
        guard canReconnectAutomatically else { return }
        
        scheduleReconnectionTimer()
    }
    
    func scheduleReconnectionTimer() {
        let delay = reconnectionStrategy.getDelayAfterTheFailure()
        
        log.debug("Timer ⏳ \(delay) sec", subsystems: .webSocket)
        
        reconnectionTimer = reconnectionTimerType.schedule(
            timeInterval: delay,
            queue: .main,
            onFire: { [weak self] in
                log.debug("Timer 🔥", subsystems: .webSocket)
                
                self?.reconnectIfNeeded()
            }
        )
    }
    
    func cancelReconnectionTimer() {
        guard reconnectionTimer != nil else { return }
        
        log.debug("Timer ❌", subsystems: .webSocket)
        
        reconnectionTimer?.cancel()
        reconnectionTimer = nil
    }
}

// MARK: - Automatic Reconnection Policies

public protocol AutomaticReconnectionPolicy {
    func canBeReconnected() -> Bool
}

struct WebSocketAutomaticReconnectionPolicy: AutomaticReconnectionPolicy {
    private var webSocketClient: WebSocketClient

    init(_ webSocketClient: WebSocketClient) {
        self.webSocketClient = webSocketClient
    }

    func canBeReconnected() -> Bool {
        webSocketClient.connectionState.isAutomaticReconnectionEnabled
    }
}

struct InternetAvailabilityReconnectionPolicy: AutomaticReconnectionPolicy {
    private var internetConnection: InternetConnection

    init(_ internetConnection: InternetConnection) {
        self.internetConnection = internetConnection
    }

    func canBeReconnected() -> Bool {
        internetConnection.status.isAvailable
    }
}

struct BackgroundStateReconnectionPolicy: AutomaticReconnectionPolicy {
    private var backgroundTaskScheduler: BackgroundTaskScheduler?

    init(_ backgroundTaskScheduler: BackgroundTaskScheduler?) {
        self.backgroundTaskScheduler = backgroundTaskScheduler
    }

    func canBeReconnected() -> Bool {
        backgroundTaskScheduler?.isAppActive ?? true
    }
}

struct CompositeReconnectionPolicy: AutomaticReconnectionPolicy {
    enum Operator { case and, or }

    private var `operator`: Operator
    private var policies: [AutomaticReconnectionPolicy]

    init(_ operator: Operator, policies: [AutomaticReconnectionPolicy]) {
        self.operator = `operator`
        self.policies = policies
    }

    func canBeReconnected() -> Bool {
        switch `operator` {
        case .and:
            policies.first { $0.canBeReconnected() == false } == nil
        case .or:
            policies.first { $0.canBeReconnected() } != nil
        }
    }
}
