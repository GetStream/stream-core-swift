//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public class WebSocketClient: @unchecked Sendable {
    /// The notification center `WebSocketClient` uses to send notifications about incoming events.
    public let eventNotificationCenter: EventNotificationCenter

    /// The batch of events received via the web-socket that wait to be processed.
    private(set) lazy var eventsBatcher = environment.eventBatcherBuilder { [weak self] events, completion in
        guard let self else { return }
        events.forEach { [eventSubject] in eventSubject.send($0) }
        eventNotificationCenter.process(events, postNotifications: true, completion: completion)
    }

    /// The current state the web socket connection.
    @Atomic public internal(set) var connectionState: WebSocketConnectionState = .initialized {
        didSet {
            pingController.connectionStateDidChange(connectionState)

            guard connectionState != oldValue else { return }

            log.info("Web socket connection state changed: \(connectionState)", subsystems: .webSocket)

            connectionSubject.send(connectionState)
            connectionStateDelegate?.webSocketClient(self, didUpdateConnectionState: connectionState)
        }
    }

    let connectionSubject = PassthroughSubject<WebSocketConnectionState, Never>()
    public let eventSubject = PassthroughSubject<Event, Never>()

    public weak var connectionStateDelegate: ConnectionStateDelegate?

    public var connectRequest: URLRequest? {
        get { _connectRequest.value }
        set { _connectRequest.value = newValue }
    }
    
    private let _connectRequest = AllocatedUnfairLock<URLRequest?>(nil)

    let requiresAuth: Bool
    /// If true, health check event is processed by the event notification center before setting connection status to connected, otherwise the order is reversed.
    /// Compatibility reasons for chat which has to set it to true.
    let healthCheckBeforeConnected: Bool

    /// The decoder used to decode incoming events
    private let eventDecoder: AnyEventDecoder

    /// The web socket engine used to make the actual WS connection
    public private(set) var engine: WebSocketEngine?

    /// The queue on which web socket engine methods are called
    private let engineQueue: DispatchQueue = .init(label: "io.getstream.core.web_socket_engine_queue", qos: .userInitiated)

    /// The session config used for the web socket engine
    private let sessionConfiguration: URLSessionConfiguration

    /// An object containing external dependencies of `WebSocketClient`
    private let environment: Environment

    private let webSocketClientType: WebSocketClientType

    let pingController: WebSocketPingController

    private func createEngineIfNeeded(for connectRequest: URLRequest) -> WebSocketEngine {
        if let existedEngine = engine, existedEngine.request == connectRequest {
            return existedEngine
        }

        let engine = environment.createEngine(connectRequest, sessionConfiguration, engineQueue)
        engine.delegate = self
        return engine
    }

    public var onWSConnectionEstablished: (() -> Void)?
    public var onConnected: (() -> Void)?

    public init(
        sessionConfiguration: URLSessionConfiguration,
        eventDecoder: AnyEventDecoder,
        eventNotificationCenter: EventNotificationCenter,
        webSocketClientType: WebSocketClientType,
        environment: Environment = Environment(eventBatchingPeriod: 0.0),
        connectRequest: URLRequest?,
        healthCheckBeforeConnected: Bool = false,
        requiresAuth: Bool = true,
        pingRequestBuilder: (() -> any SendableEvent)? = nil
    ) {
        self.environment = environment
        self.sessionConfiguration = sessionConfiguration
        self.webSocketClientType = webSocketClientType
        self.eventDecoder = eventDecoder
        self._connectRequest.value = connectRequest
        self.eventNotificationCenter = eventNotificationCenter
        self.healthCheckBeforeConnected = healthCheckBeforeConnected
        self.requiresAuth = requiresAuth
        pingController = environment.createPingController(
            environment.timerType,
            engineQueue,
            webSocketClientType
        )
        pingController.pingRequestBuilder = pingRequestBuilder
        
        pingController.delegate = self
    }
    
    /// Sets connection status to ``ConnectionStatus.initialized``.
    ///
    /// - Note: Used for sophisticated reconnection flows in chat.
    /// - Important: Does not disconnect the client if it was already connected.
    public func initialize() {
        connectionState = .initialized
    }

    /// Connects the web connect.
    ///
    /// Calling this method has no effect is the web socket is already connected, or is in the connecting phase.
    public func connect() {
        switch connectionState {
        // Calling connect in the following states has no effect
        case .connecting, .authenticating, .connected:
            return
        default: break
        }

        guard let connectRequest else { return }
        engineQueue.sync {
            engine = createEngineIfNeeded(for: connectRequest)
        }

        connectionState = .connecting

        engineQueue.async { [weak engine] in
            engine?.connect()
        }
    }

    /// Disconnects the web socket.
    ///
    /// Calling this function has no effect, if the connection is in an inactive state.
    /// - Parameter source: Additional information about the source of the disconnection. Default value is `.userInitiated`.
    public func disconnect(
        code: URLSessionWebSocketTask.CloseCode = .normalClosure,
        source: WebSocketConnectionState.DisconnectionSource = .userInitiated,
        completion: @Sendable @escaping () -> Void
    ) {
        connectionState = .disconnecting(source: source)
        engineQueue.async { [engine, eventsBatcher] in
            engine?.disconnect(with: code)

            eventsBatcher.processImmediately(completion: completion)
        }
    }

    public func disconnect(source: WebSocketConnectionState.DisconnectionSource = .userInitiated) async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume()
                return
            }
            disconnect {
                continuation.resume()
            }
        }
    }
    
    /// Publishes an event locally by forwarding it to the events batcher.
    ///
    /// Use it for custom events.
    ///
    /// - Parameter event: The event to be published locally.
    public func publishEvent(_ event: Event) {
        eventsBatcher.append(event)
    }
}

public protocol ConnectionStateDelegate: AnyObject {
    func webSocketClient(_ client: WebSocketClient, didUpdateConnectionState state: WebSocketConnectionState)
}

public extension WebSocketClient {
    /// An object encapsulating all dependencies of `WebSocketClient`.
    struct Environment {
        typealias CreatePingController = (
            _ timerType: TimerScheduling.Type,
            _ timerQueue: DispatchQueue,
            _ webSocketClientType: WebSocketClientType
        ) -> WebSocketPingController

        typealias CreateEngine = (
            _ request: URLRequest,
            _ sessionConfiguration: URLSessionConfiguration,
            _ callbackQueue: DispatchQueue
        ) -> WebSocketEngine

        var timerType: TimerScheduling.Type = DefaultTimer.self

        var createPingController: CreatePingController = WebSocketPingController.init

        var createEngine: CreateEngine = {
            URLSessionWebSocketEngine(request: $0, sessionConfiguration: $1, callbackQueue: $2)
        }

        var eventBatcherBuilder: (
            _ handler: @Sendable @escaping ([Event], @Sendable @escaping () -> Void) -> Void
        ) -> EventBatcher = {
            Batcher<Event>(period: 0.0, handler: $0)
        }
        
        public init(
            eventBatchingPeriod: TimeInterval
        ) {
            eventBatcherBuilder = {
                Batcher<Event>(period: eventBatchingPeriod, handler: $0)
            }
        }
        
        init(
            timerType: TimerScheduling.Type = DefaultTimer.self,
            createPingController: @escaping CreatePingController,
            createEngine: @escaping CreateEngine,
            eventBatcherBuilder: @escaping (
                _ handler: @Sendable @escaping ([Event], @Sendable @escaping () -> Void) -> Void
            ) -> EventBatcher
        ) {
            self.timerType = timerType
            self.createPingController = createPingController
            self.createEngine = createEngine
            self.eventBatcherBuilder = eventBatcherBuilder
        }
    }
}

// MARK: - Web Socket Delegate

extension WebSocketClient: WebSocketEngineDelegate {
    public func webSocketDidConnect() {
        log.debug("Web socket connection established", subsystems: .webSocket)
        connectionState = .authenticating
        onWSConnectionEstablished?()
    }

    public func webSocketDidReceiveMessage(_ data: Data) {
        var event: Event

        do {
            event = try eventDecoder.decode(from: data)
        } catch is ClientError.IgnoredEventType {
            log.info("Skipping unsupported event type with payload: \(data.debugPrettyPrintedJSON)", subsystems: .webSocket)
            return
        } catch {
            do {
                // Web socket errors are typically handled by connection events which event decoder handles.
                // For example: token expiration error triggers connection event which implements `error()` and
                // leads to disconnecting the web-socket client below. This is here for logging purposes for
                // notifying that connection event was not handled.
                let apiError = try JSONDecoder.streamCore.decode(APIErrorContainer.self, from: data).error
                log.error("Web socket error \(apiError.message)", subsystems: .webSocket, error: apiError)
            } catch let decodingError {
                log.warning(
                    """
                    Decoding websocket payload failed
                    payload: \(String(data: data, encoding: .utf8) ?? "-")

                    Error: \(decodingError)
                    """,
                    subsystems: .webSocket
                )
            }
            return
        }

        if let error = event.error() {
            log.error("Received an error webSocket event.", subsystems: .webSocket, error: error)
            connectionState = .disconnecting(source: .serverInitiated(error: ClientError(with: error)))
            return
        } else {
            log.info("Received webSocket event \(event.name).", subsystems: .webSocket)
        }

        // healthcheck events are not passed to batcher
        if let info = event.healthcheck() {
            handle(healthcheck: event, info: info)
            return
        }

        eventsBatcher.append(event)
    }

    public func webSocketDidDisconnect(error engineError: WebSocketEngineError?) {
        switch connectionState {
        case .connecting, .authenticating, .connected:
            let serverError = engineError.map { ClientError.WebSocket(with: $0) }

            connectionState = .disconnected(source: .serverInitiated(error: serverError))

        case let .disconnecting(source):
            connectionState = .disconnected(source: source)

        case .initialized, .disconnected:
            log.error(
                "Web socket can not be disconnected when in \(connectionState) state",
                subsystems: .webSocket,
                error: engineError
            )
        }
    }

    private func handle(healthcheck: Event, info: HealthCheckInfo) {
        log.debug("Handling healthcheck", subsystems: .webSocket)

        if !healthCheckBeforeConnected, connectionState == .authenticating {
            connectionState = .connected(healthCheckInfo: info)
            onConnected?()
        }
        // We send the healthcheck to the eventSubject so that observers
        // (e.g. SFUEventAdapter) get updated.
        eventSubject.send(healthcheck)
        eventNotificationCenter.process(healthcheck, postNotification: false) { [weak self] in
            self?.engineQueue.async { [weak self] in
                guard let self else { return }
                self.pingController.pongReceived()
                self.connectionState = .connected(healthCheckInfo: info)
                if self.healthCheckBeforeConnected {
                    self.onConnected?()
                }
            }
        }
    }
}

// MARK: - Ping Controller Delegate

extension WebSocketClient: WebSocketPingControllerDelegate {
    func sendPing(healthCheckEvent: SendableEvent) {
        engineQueue.async { [weak engine] in
            if case .connected = self.connectionState {
                engine?.send(message: healthCheckEvent)
            }
        }
    }

    func sendPing() {
        engine?.sendPing()
    }

    func disconnectOnNoPongReceived() {
        log.debug("disconnecting from \(String(describing: connectRequest?.url))", subsystems: .webSocket)
        disconnect(source: .noPongReceived) {
            log.debug("Websocket is disconnected because of no pong received", subsystems: .webSocket)
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// The name of the notification posted when a new event is published/
    public static let NewEventReceived = Notification.Name("io.getstream.core.new_event_received")
}

public enum WebSocketClientType {
    case coordinator
    case sfu
}

extension Notification {
    private static let eventKey = "io.getstream.core.event_key"

    public init(newEventReceived event: Event, sender: Any) {
        self.init(name: .NewEventReceived, object: sender, userInfo: [Self.eventKey: event])
    }

    public var event: Event? {
        userInfo?[Self.eventKey] as? Event
    }
}

// MARK: - Test helpers

#if TESTS
extension WebSocketClient {
    /// Simulates connection status change
    func simulateConnectionStatus(_ status: WebSocketConnectionState) {
        connectionState = status
    }
}
#endif

extension ClientError {
    public class WebSocket: ClientError, @unchecked Sendable {}
    
    public final class IgnoredEventType: ClientError, @unchecked Sendable {
        override public var localizedDescription: String { "The incoming event type is not supported. Ignoring." }
    }
}

public struct WSDisconnected: Event {
    public init() {}
}

public struct WSConnected: Event {
    public init() {}
}
