//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public var log: Logger {
    LogConfig.logger
}

/// Entity for identifying which subsystem the log message comes from.
public struct LogSubsystem: OptionSet, CustomStringConvertible, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let allCases: [LogSubsystem] = [
        .database,
        .httpRequests,
        .webSocket,
        .webRTC,
        .other,
        .offlineSupport,
        .peerConnectionPublisher,
        .peerConnectionSubscriber,
        .sfu,
        .iceAdapter,
        .mediaAdapter,
        .thermalState,
        .audioSession,
        .videoCapturer,
        .pictureInPicture,
        .callKit
    ]

    /// All subsystems within the SDK.
    public static let all: LogSubsystem = [
        .database,
        .httpRequests,
        .webSocket,
        .webRTC,
        .other,
        .offlineSupport,
        .peerConnectionPublisher,
        .peerConnectionSubscriber,
        .sfu,
        .iceAdapter,
        .mediaAdapter,
        .thermalState,
        .audioSession,
        .videoCapturer,
        .pictureInPicture,
        .callKit
    ]
    
    /// The subsystem responsible for any other part of the SDK.
    /// This is the default subsystem value for logging, to be used when `subsystem` is not specified.
    public static let other = Self(rawValue: 1 << 0)
    
    /// The subsystem responsible for database operations.
    public static let database = Self(rawValue: 1 << 1)
    /// The subsystem responsible for HTTP operations.
    public static let httpRequests = Self(rawValue: 1 << 2)
    /// The subsystem responsible for websocket operations.
    public static let webSocket = Self(rawValue: 1 << 3)
    /// The subsystem responsible for offline support.
    public static let offlineSupport = Self(rawValue: 1 << 4)
    /// The subsystem responsible for WebRTC.
    public static let webRTC = Self(rawValue: 1 << 5)
    /// The subsystem responsible for PeerConnections.
    public static let peerConnectionPublisher = Self(rawValue: 1 << 6)
    public static let peerConnectionSubscriber = Self(rawValue: 1 << 7)
    /// The subsystem responsible for SFU interaction.
    public static let sfu = Self(rawValue: 1 << 8)
    /// The subsystem responsible for ICE interactions.
    public static let iceAdapter = Self(rawValue: 1 << 9)
    /// The subsystem responsible for Media publishing/subscribing.
    public static let mediaAdapter = Self(rawValue: 1 << 10)
    /// The subsystem responsible for ThermalState observation.
    public static let thermalState = Self(rawValue: 1 << 11)
    /// The subsystem responsible for interacting with the AudioSession.
    public static let audioSession = Self(rawValue: 1 << 12)
    /// The subsystem responsible for VideoCapturing components.
    public static let videoCapturer = Self(rawValue: 1 << 13)
    /// The subsystem responsible for PicutreInPicture.
    public static let pictureInPicture = Self(rawValue: 1 << 14)
    /// The subsystem responsible for PicutreInPicture.
    public static let callKit = Self(rawValue: 1 << 15)

    public var description: String {
        switch rawValue {
        case LogSubsystem.other.rawValue:
            "other"
        case LogSubsystem.database.rawValue:
            "database"
        case LogSubsystem.httpRequests.rawValue:
            "httpRequests"
        case LogSubsystem.webSocket.rawValue:
            "webSocket"
        case LogSubsystem.offlineSupport.rawValue:
            "offlineSupport"
        case LogSubsystem.webRTC.rawValue:
            "webRTC"
        case LogSubsystem.peerConnectionPublisher.rawValue:
            "peerConnection-publisher"
        case LogSubsystem.peerConnectionSubscriber.rawValue:
            "peerConnection-subscriber"
        case LogSubsystem.sfu.rawValue:
            "sfu"
        case LogSubsystem.iceAdapter.rawValue:
            "iceAdapter"
        case LogSubsystem.mediaAdapter.rawValue:
            "mediaAdapter"
        case LogSubsystem.thermalState.rawValue:
            "thermalState"
        case LogSubsystem.audioSession.rawValue:
            "audioSession"
        case LogSubsystem.videoCapturer.rawValue:
            "videoCapturer"
        case LogSubsystem.pictureInPicture.rawValue:
            "picture-in-picture"
        case LogSubsystem.callKit.rawValue:
            "CallKit"
        default:
            "unknown(rawValue:\(rawValue)"
        }
    }
}

public enum LogConfig {
    struct Configuration {
        var identifier: String = ""
        var level: LogLevel = .error
        var dateFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return df
        }()

        var formatters: [LogFormatter] = []
        var showDate: Bool = true
        var showLevel: Bool = true
        var showIdentifier: Bool = false
        var showThreadName: Bool = true
        var showFileName: Bool = true
        var showLineNumber: Bool = true
        var showFunctionName: Bool = true
        var subsystems: LogSubsystem = .all
        var destinationTypes: [LogDestination.Type] = LogConfig.defaultDestinations
    }
    
    static let configuration = AllocatedUnfairLock<Configuration>(Configuration())
    
    /// Identifier for the logger. Defaults to empty.
    public static var identifier: String {
        get {
            configuration.withLock { $0.identifier }
        }
        set {
            configuration.withLock { $0.identifier = newValue }
            invalidateLogger()
        }
    }
    
    /// Output level for the logger.
    public static var level: LogLevel {
        get {
            configuration.withLock { $0.level }
        }
        set {
            configuration.withLock { $0.level = newValue }
            invalidateLogger()
        }
    }
    
    /// Date formatter for the logger. Defaults to ISO8601
    public static var dateFormatter: DateFormatter {
        get {
            configuration.withLock { $0.dateFormatter }
        }
        set {
            configuration.withLock { $0.dateFormatter = newValue }
            invalidateLogger()
        }
    }
    
    /// Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters).
    /// Please see `LogFormatter` for more info.
    public static var formatters: [LogFormatter] {
        get {
            configuration.withLock { $0.formatters }
        }
        set {
            configuration.withLock { $0.formatters = newValue }
            invalidateLogger()
        }
    }
    
    /// Toggle for showing date in logs
    public static var showDate: Bool {
        get {
            configuration.withLock { $0.showDate }
        }
        set {
            configuration.withLock { $0.showDate = newValue }
            invalidateLogger()
        }
    }
    
    /// Toggle for showing log level in logs
    public static var showLevel: Bool {
        get {
            configuration.withLock { $0.showLevel }
        }
        set {
            configuration.withLock { $0.showLevel = newValue }
            invalidateLogger()
        }
    }
    
    /// Toggle for showing identifier in logs
    public static var showIdentifier: Bool {
        get {
            configuration.withLock { $0.showIdentifier }
        }
        set {
            configuration.withLock { $0.showIdentifier = newValue }
            invalidateLogger()
        }
    }
    
    /// Toggle for showing thread name in logs
    public static var showThreadName: Bool {
        get {
            configuration.withLock { $0.showThreadName }
        }
        set {
            configuration.withLock { $0.showThreadName = newValue }
            invalidateLogger()
        }
    }
    
    /// Toggle for showing file name in logs
    public static var showFileName: Bool {
        get {
            configuration.withLock { $0.showFileName }
        }
        set {
            configuration.withLock { $0.showFileName = newValue }
            invalidateLogger()
        }
    }
    
    /// Toggle for showing line number in logs
    public static var showLineNumber: Bool {
        get {
            configuration.withLock { $0.showLineNumber }
        }
        set {
            configuration.withLock { $0.showLineNumber = newValue }
            invalidateLogger()
        }
    }
    
    /// Toggle for showing function name in logs
    public static var showFunctionName: Bool {
        get {
            configuration.withLock { $0.showFunctionName }
        }
        set {
            configuration.withLock { $0.showFunctionName = newValue }
            invalidateLogger()
        }
    }
    
    /// Subsystems for the logger
    public static var subsystems: LogSubsystem {
        get {
            configuration.withLock { $0.subsystems }
        }
        set {
            configuration.withLock { $0.subsystems = newValue }
            invalidateLogger()
        }
    }
    
    /// Destination types this logger will use.
    ///
    /// Logger will initialize the destinations with its own parameters. If you want full control on the parameters, use `destinations` directly,
    /// where you can pass parameters to destination initializers yourself.
    public static var destinationTypes: [LogDestination.Type] {
        get {
            configuration.withLock { $0.destinationTypes }
        }
        set {
            configuration.withLock { $0.destinationTypes = newValue }
            invalidateLogger()
        }
    }
    
    static var defaultDestinations: [LogDestination.Type] {
        if #available(iOS 14.0, *) {
            [OSLogDestination.self]
        } else {
            [ConsoleLogDestination.self]
        }
    }
    
    private static let _destinations = AllocatedUnfairLock<[LogDestination]?>(nil)

    /// Destinations for the default logger. Please see `LogDestination`.
    /// Defaults to only `ConsoleLogDestination`, which only prints the messages.
    ///
    /// - Important: Other options in `ChatClientConfig.Logging` will not take affect if this is changed.
    public static var destinations: [LogDestination] {
        get {
            _destinations.withLock { destinations in
                if let destinations {
                    return destinations
                } else {
                    let state = configuration.withLock { $0 }
                    let newDestinations = state.destinationTypes.map {
                        $0.init(
                            identifier: state.identifier,
                            level: state.level,
                            subsystems: state.subsystems,
                            showDate: state.showDate,
                            dateFormatter: state.dateFormatter,
                            formatters: state.formatters,
                            showLevel: state.showLevel,
                            showIdentifier: state.showIdentifier,
                            showThreadName: state.showThreadName,
                            showFileName: state.showFileName,
                            showLineNumber: state.showLineNumber,
                            showFunctionName: state.showFunctionName
                        )
                    }
                    destinations = newDestinations
                    return newDestinations
                }
            }
        }
        set {
            _destinations.withLock { $0 = newValue }
            invalidateLogger()
        }
    }
    
    /// Underlying logger instance to control singleton.
    private static let _logger = AllocatedUnfairLock<Logger?>(nil)

    /// Logger instance to be used by StreamChat.
    ///
    /// - Important: Other options in `LogConfig` will not take affect if this is changed.
    public static var logger: Logger {
        get {
            _logger.withLock { logger in
                if let logger {
                    return logger
                } else {
                    let state = configuration.withLock { $0 }
                    let newLogger = Logger(identifier: state.identifier, destinations: destinations)
                    logger = newLogger
                    return newLogger
                }
            }
        }
        set {
            _logger.withLock { $0 = newValue }
        }
    }
    
    /// Invalidates the current logger instance so it can be recreated.
    private static func invalidateLogger() {
        _logger.withLock { $0 = nil }
        _destinations.withLock { $0 = nil }
    }
}

/// Entity used for logging messages.
public class Logger {
    /// Identifier of the Logger. Will be visible if a destination has `showIdentifiers` enabled.
    public let identifier: String
    
    /// Destinations for this logger.
    /// See `LogDestination` protocol for details.
    public var destinations: [LogDestination]
    
    private let loggerQueue = DispatchQueue(label: "LoggerQueue \(UUID())")
    
    /// Init a logger with a given identifier and destinations.
    public init(identifier: String = "", destinations: [LogDestination] = []) {
        self.identifier = identifier
        self.destinations = destinations
    }
    
    /// Allows logger to be called as function.
    /// Transforms, given that `let log = Logger()`, `log.log(.info, "Hello")` to `log(.info, "Hello")` for ease of use.
    ///
    /// - Parameters:
    ///   - level: Log level for this message
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    ///   - message: Message to be logged
    public func callAsFunction(
        _ level: LogLevel,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line,
        message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        error: Error?
    ) {
        log(
            level,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: error
        )
    }
    
    /// Log a message to all enabled destinations.
    /// See  `Logger.destinations` for customizing the output.
    ///
    /// - Parameters:
    ///   - level: Log level for this message
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    ///   - message: Message to be logged
    public func log(
        _ level: LogLevel,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line,
        message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        error: Error?
    ) {
        let enabledDestinations = destinations.filter { $0.isEnabled(level: level, subsystems: subsystems) }
        guard !enabledDestinations.isEmpty else { return }
        
        let logDetails = LogDetails(
            loggerIdentifier: identifier,
            subsystem: subsystems,
            level: level,
            date: Date(),
            message: String(describing: message()),
            threadName: threadName,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            error: error
        )
        for destination in enabledDestinations {
            loggerQueue.async {
                destination.process(logDetails: logDetails)
            }
        }
    }
    
    /// Log an info message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func info(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        log(
            .info,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: nil
        )
    }
    
    /// Log a debug message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func debug(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        log(
            .debug,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: nil
        )
    }
    
    /// Log a warning message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func warning(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        log(
            .warning,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: nil
        )
    }
    
    /// Log an error message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func error(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        error: Error? = nil,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        // If the error isn't conforming to ``ReflectiveStringConvertible`` we
        // wrap it in a ``ClientError`` to provide consistent logging information.
        let error = {
            guard let error, (error as? ReflectiveStringConvertible) == nil else {
                return error
            }
            return ClientError(with: error, fileName, lineNumber)
        }()

        log(
            .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: error
        )
    }
    
    /// Performs `Swift.assert` and stops program execution if `condition` evaluated to false. In RELEASE builds only
    /// logs the failure.
    ///
    /// - Parameters:
    ///   - condition: The condition to test.
    ///   - message: A custom message to log if `condition` is evaluated to false.
    public func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        guard !condition() else { return }
        if StreamRuntimeCheck.assertionsEnabled {
            Swift.assert(condition(), String(describing: message()), file: fileName, line: lineNumber)
        }
        log(
            .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: "Assert failed: \(message())",
            subsystems: subsystems,
            error: nil
        )
    }
    
    /// Stops program execution with `Swift.assertionFailure`. In RELEASE builds only
    /// logs the failure.
    ///
    /// - Parameters:
    ///   - message: A custom message to log if `condition` is evaluated to false.
    public func assertionFailure(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        if StreamRuntimeCheck.assertionsEnabled {
            Swift.assertionFailure(String(describing: message()), file: fileName, line: lineNumber)
        }
        log(
            .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: "Assert failed: \(message())",
            subsystems: subsystems,
            error: nil
        )
    }
}

private extension Logger {
    var threadName: String {
        if Thread.isMainThread {
            "[main] "
        } else {
            if let threadName = Thread.current.name, !threadName.isEmpty {
                "[\(threadName)] "
            } else if
                let queueName = String(validatingCString: __dispatch_queue_get_label(nil)), !queueName.isEmpty {
                "[\(queueName)] "
            } else {
                String(format: "[%p] ", Thread.current)
            }
        }
    }
}

extension Data {
    /// Converts the data into a pretty-printed JSON string. Use only for debug purposes since this operation can be expensive.
    var debugPrettyPrintedJSON: String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            let prettyPrintedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            return String(data: prettyPrintedData, encoding: .utf8) ?? "Error: Data to String decoding failed."
        } catch {
            return "<not available string representation>"
        }
    }
}
