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
        .callKit,
        .authentication,
        .audioPlayback,
        .audioRecording
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
        .callKit,
        .authentication,
        .audioPlayback,
        .audioRecording
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
    /// The subsystem responsible for authentication.
    public static let authentication = Self(rawValue: 1 << 16)
    /// The subsystem responsible for audio playback.
    public static let audioPlayback = Self(rawValue: 1 << 17)
    /// The subsystem responsible for audio recording.
    public static let audioRecording = Self(rawValue: 1 << 18)

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
        case LogSubsystem.authentication.rawValue:
            "authentication"
        case LogSubsystem.audioPlayback.rawValue:
            "audio-playback"
        case LogSubsystem.audioRecording.rawValue:
            "audio-recording"
        default:
            "unknown(rawValue:\(rawValue)"
        }
    }
}

public enum LogConfig {
    private struct State {
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
        
        var destinationTypes: [LogDestination.Type] = if #available(iOS 14.0, *) {
            [OSLogDestination.self]
        } else {
            [ConsoleLogDestination.self]
        }
        
        private var _destinations: [LogDestination]?
        
        var destinations: [LogDestination] {
            mutating get {
                if let _destinations {
                    return _destinations
                }
                let newDestinations = destinationTypes.map {
                    $0.init(
                        identifier: identifier,
                        level: level,
                        subsystems: subsystems,
                        showDate: showDate,
                        dateFormatter: dateFormatter,
                        formatters: formatters,
                        showLevel: showLevel,
                        showIdentifier: showIdentifier,
                        showThreadName: showThreadName,
                        showFileName: showFileName,
                        showLineNumber: showLineNumber,
                        showFunctionName: showFunctionName
                    )
                }
                _destinations = newDestinations
                return newDestinations
            }
            set {
                _destinations = newValue
            }
        }
        
        private var _logger: Logger?
        
        var logger: Logger {
            mutating get {
                if let _logger {
                    return _logger
                }
                let logger = Logger(identifier: identifier, destinations: destinations)
                _logger = logger
                return logger
            }
            set {
                _logger = newValue
            }
        }
        
        mutating func invalidateLogger() {
            _destinations = nil
            _logger = nil
        }
    }
    
    private static let _state = AllocatedUnfairLock<State>(State())
    
    /// Identifier for the logger. Defaults to empty.
    public static var identifier: String {
        get {
            _state.withLock { $0.identifier }
        }
        set {
            _state.withLock {
                $0.identifier = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Output level for the logger.
    public static var level: LogLevel {
        get {
            _state.withLock { $0.level }
        }
        set {
            _state.withLock {
                $0.level = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Date formatter for the logger. Defaults to ISO8601
    public static var dateFormatter: DateFormatter {
        get {
            _state.withLock { $0.dateFormatter }
        }
        set {
            _state.withLock {
                $0.dateFormatter = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters).
    /// Please see `LogFormatter` for more info.
    public static var formatters: [LogFormatter] {
        get {
            _state.withLock { $0.formatters }
        }
        set {
            _state.withLock {
                $0.formatters = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Toggle for showing date in logs
    public static var showDate: Bool {
        get {
            _state.withLock { $0.showDate }
        }
        set {
            _state.withLock {
                $0.showDate = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Toggle for showing log level in logs
    public static var showLevel: Bool {
        get {
            _state.withLock { $0.showLevel }
        }
        set {
            _state.withLock {
                $0.showLevel = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Toggle for showing identifier in logs
    public static var showIdentifier: Bool {
        get {
            _state.withLock { $0.showIdentifier }
        }
        set {
            _state.withLock {
                $0.showIdentifier = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Toggle for showing thread name in logs
    public static var showThreadName: Bool {
        get {
            _state.withLock { $0.showThreadName }
        }
        set {
            _state.withLock {
                $0.showThreadName = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Toggle for showing file name in logs
    public static var showFileName: Bool {
        get {
            _state.withLock { $0.showFileName }
        }
        set {
            _state.withLock {
                $0.showFileName = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Toggle for showing line number in logs
    public static var showLineNumber: Bool {
        get {
            _state.withLock { $0.showLineNumber }
        }
        set {
            _state.withLock {
                $0.showLineNumber = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Toggle for showing function name in logs
    public static var showFunctionName: Bool {
        get {
            _state.withLock { $0.showFunctionName }
        }
        set {
            _state.withLock {
                $0.showFunctionName = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Subsystems for the logger
    public static var subsystems: LogSubsystem {
        get {
            _state.withLock { $0.subsystems }
        }
        set {
            _state.withLock {
                $0.subsystems = newValue
                $0.invalidateLogger()
            }
        }
    }
    
    /// Destination types this logger will use.
    ///
    /// Logger will initialize the destinations with its own parameters. If you want full control on the parameters, use `destinations` directly,
    /// where you can pass parameters to destination initializers yourself.
    public static var destinationTypes: [LogDestination.Type] {
        get {
            _state.withLock { $0.destinationTypes }
        }
        set {
            _state.withLock {
                $0.destinationTypes = newValue
                $0.invalidateLogger()
            }
        }
    }

    /// Destinations for the default logger. Please see `LogDestination`.
    /// Defaults to only `ConsoleLogDestination`, which only prints the messages.
    ///
    /// - Important: Other options in `ChatClientConfig.Logging` will not take affect if this is changed.
    public static var destinations: [LogDestination] {
        get {
            _state.withLock { $0.destinations }
        }
        set {
            _state.withLock {
                // Order is important
                $0.invalidateLogger()
                $0.destinations = newValue
            }
        }
    }

    /// Logger instance to be used by StreamChat.
    ///
    /// - Important: Other options in `LogConfig` will not take affect if this is changed.
    public static var logger: Logger {
        get {
            _state.withLock { $0.logger }
        }
        set {
            _state.withLock { $0.logger = newValue }
        }
    }
    
    static func reset() {
        _state.withLock { $0 = State() }
    }
}

/// Entity used for logging messages.
open class Logger {
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
    open func assert(
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
    open func assertionFailure(
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
    public var debugPrettyPrintedJSON: String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            let prettyPrintedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            return String(data: prettyPrintedData, encoding: .utf8) ?? "Error: Data to String decoding failed."
        } catch {
            return "<not available string representation>"
        }
    }
}
