//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import OSLog

@available(iOS 14.0, *)
public final class OSLogDestination: BaseLogDestination, @unchecked Sendable {
    private let loggers: [String: os.Logger] = LogSubsystem
        .allCases
        .reduce(into: [String: os.Logger]()) {
            partialResult,
                subsystem in
            partialResult[subsystem.description] = .init(
                subsystem: subsystem.description,
                category: "Video"
            )
        }

    override public func process(logDetails: LogDetails) {
        guard let logger = loggers[logDetails.subsystem.description] else {
            return
        }
        var extendedDetails: String = ""

        if showIdentifier {
            extendedDetails += "[\(logDetails.loggerIdentifier)-\(identifier)] "
        }

        if showFileName {
            let fileName = (String(describing: logDetails.fileName) as NSString).lastPathComponent
            extendedDetails += "[\(fileName)\(showLineNumber ? ":\(logDetails.lineNumber)" : "")] "
        } else if showLineNumber {
            extendedDetails += "[\(logDetails.lineNumber)] "
        }

        if showFunctionName {
            extendedDetails += "[\(logDetails.functionName)] "
        }

        if showThreadName {
            extendedDetails += logDetails.threadName
        }

        var extendedMessage = "\(extendedDetails)> \(logDetails.message)"
        if let error = logDetails.error {
            extendedMessage += "\n\(error)"
        }
        let formattedMessage = LogConfig
            .formatters
            .reduce(extendedMessage) { $1.format(logDetails: logDetails, message: $0) }
        let type = Self.osLogType(for: logDetails.level)
        if let attachment = logDetails.attachment {
            // Attachments hold request and response bodies, so they are private: devices redact them from collected logs.
            logger.log(level: type, "\(formattedMessage, privacy: .public)\n\(attachment.logDescription, privacy: .private)")
        } else {
            logger.log(level: type, "\(formattedMessage, privacy: .public)")
        }
    }

    private static func osLogType(for level: LogLevel) -> OSLogType {
        switch level {
        case .debug: .debug
        case .info: .default
        case .warning, .error: .error
        }
    }
}
