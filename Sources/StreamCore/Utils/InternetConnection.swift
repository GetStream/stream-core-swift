//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import Network

extension Notification.Name {
    /// Posted when any the Internet connection update is detected (including quality updates).
    public static let internetConnectionStatusDidChange = Self("io.getstream.core.internetConnectionStatus")

    /// Posted only when the Internet connection availability is changed (excluding quality updates).
    public static let internetConnectionAvailabilityDidChange = Self("io.getstream.core.internetConnectionAvailability")
}

extension Notification {
    static let internetConnectionStatusUserInfoKey = "internetConnectionStatus"

    public var internetConnectionStatus: InternetConnectionStatus? {
        userInfo?[Self.internetConnectionStatusUserInfoKey] as? InternetConnectionStatus
    }
}

/// An Internet Connection monitor.
///
/// Basically, it's a wrapper over legacy monitor based on `Reachability` (iOS 11 only)
/// and default monitor based on `Network`.`NWPathMonitor` (iOS 12+).
open class InternetConnection: @unchecked Sendable {
    /// The current Internet connection status.
    @Published private(set) var status: InternetConnectionStatus {
        didSet {
            guard oldValue != status else { return }

            log.info("Internet Connection: \(status)", subsystems: .httpRequests)

            postNotification(.internetConnectionStatusDidChange, with: status)

            guard oldValue.isAvailable != status.isAvailable else { return }

            postNotification(.internetConnectionAvailabilityDidChange, with: status)
        }
    }

    /// The notification center that posts notifications when connection state changes..
    public let notificationCenter: NotificationCenter

    /// A specific Internet connection monitor.
    private var monitor: InternetConnectionMonitor

    /// Creates a `InternetConnection` with a given monitor.
    /// - Parameter monitor: an Internet connection monitor. Use nil for a default `InternetConnectionMonitor`.
    public init(
        notificationCenter: NotificationCenter = .default,
        monitor: InternetConnectionMonitor
    ) {
        self.notificationCenter = notificationCenter
        self.monitor = monitor

        status = monitor.status
        monitor.delegate = self
        monitor.start()
    }

    deinit {
        monitor.stop()
    }
}

extension InternetConnection: InternetConnectionDelegate {
    public func internetConnectionStatusDidChange(status: InternetConnectionStatus) {
        self.status = status
    }
}

private extension InternetConnection {
    func postNotification(_ name: Notification.Name, with status: InternetConnectionStatus) {
        notificationCenter.post(
            name: name,
            object: self,
            userInfo: [Notification.internetConnectionStatusUserInfoKey: status]
        )
    }
}

// MARK: - Internet Connection Monitors

/// A delegate to receive Internet connection events.
public protocol InternetConnectionDelegate: AnyObject {
    /// Calls when the Internet connection status did change.
    /// - Parameter status: an Internet connection status.
    func internetConnectionStatusDidChange(status: InternetConnectionStatus)
}

/// A protocol for Internet connection monitors.
public protocol InternetConnectionMonitor: AnyObject, Sendable {
    /// A delegate for receiving Internet connection events.
    var delegate: InternetConnectionDelegate? { get set }

    /// The current status of Internet connection.
    var status: InternetConnectionStatus { get }

    /// Start Internet connection monitoring.
    func start()
    /// Stop Internet connection monitoring.
    func stop()
}

// MARK: Internet Connection Subtypes

/// The Internet connectivity status.
public enum InternetConnectionStatus: Equatable, Sendable {
    /// Notification of an Internet connection has not begun.
    case unknown

    /// The Internet is available with a specific `Quality` level.
    case available(InternetConnectionQuality)

    /// The Internet is unavailable.
    case unavailable
}

/// The Internet connectivity status quality.
public enum InternetConnectionQuality: Equatable, Sendable {
    /// The Internet connection is great (like Wi-Fi).
    case great

    /// Internet connection uses an interface that is considered expensive, such as Cellular or a Personal Hotspot.
    case expensive

    /// Internet connection uses Low Data Mode.
    /// Recommendations for Low Data Mode: don't autoplay video, music (high-quality) or gifs (big files).
    /// Supports only by iOS 13+
    case constrained
}

extension InternetConnectionStatus {
    /// Returns `true` if the internet connection is available, ignoring the quality of the connection.
    public var isAvailable: Bool {
        if case .available = self {
            true
        } else {
            false
        }
    }
}

// MARK: - Internet Connection Monitor

extension InternetConnection {
    /// The default Internet connection monitor for iOS 12+.
    /// It uses Apple Network API.
    public class Monitor: InternetConnectionMonitor, @unchecked Sendable {
        private var monitor: NWPathMonitor?
        private let queue = DispatchQueue(label: "io.getstream.internet-monitor")

        public weak var delegate: InternetConnectionDelegate?

        public var status: InternetConnectionStatus {
            if let path = monitor?.currentPath {
                return status(from: path)
            }

            return .unknown
        }
        
        public init() {}

        public func start() {
            guard monitor == nil else { return }

            monitor = createMonitor()
            monitor?.start(queue: queue)
        }

        public func stop() {
            monitor?.cancel()
            monitor = nil
        }

        private func createMonitor() -> NWPathMonitor {
            let monitor = NWPathMonitor()

            // We should be able to do `[weak self]` here, but it seems `NWPathMonitor` sometimes calls the handler
            // event after `cancel()` has been called on it.
            monitor.pathUpdateHandler = { [weak self] in
                self?.updateStatus(with: $0)
            }
            return monitor
        }

        private func updateStatus(with path: NWPath) {
            log.info("Internet Connection info: \(path.debugDescription)", subsystems: .httpRequests)
            delegate?.internetConnectionStatusDidChange(status: status(from: path))
        }

        private func status(from path: NWPath) -> InternetConnectionStatus {
            guard path.status == .satisfied else {
                return .unavailable
            }

            let quality: InternetConnectionQuality
            quality = path.isConstrained ? .constrained : (path.isExpensive ? .expensive : .great)

            return .available(quality)
        }

        deinit {
            stop()
        }
    }
}

/// A protocol defining the interface for internet connection monitoring.
public protocol InternetConnectionProtocol {
    /// A publisher that emits the current internet connection status.
    ///
    /// This publisher never fails and continuously updates with the latest
    /// connection status.
    var statusPublisher: AnyPublisher<InternetConnectionStatus, Never> { get }
}

extension InternetConnection: InternetConnectionProtocol {
    /// A publisher that emits the current internet connection status.
    ///
    /// This implementation uses a published property wrapper and erases the
    /// type to `AnyPublisher`.
    ///
    /// - Note: The publisher won't publish any duplicates.
    public var statusPublisher: AnyPublisher<InternetConnectionStatus, Never> {
        $status.removeDuplicates().eraseToAnyPublisher()
    }
}
