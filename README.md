# StreamCore (Swift)

**⚠️ Internal SDK — Not for public use**

This is the internal Swift SDK that powers several of Stream’s products (`StreamFeeds`, and soon `StreamChat` and `StreamVideo`). 

It provides shared low-level utilities, such as:

- A robust WebSocket client
- Retry/backoff logic
- Logging and monitoring tools
- Dependency injection and lightweight service containers
- Support for uploading attachments
- User models
- Other utils that are used in the products

## 🔒 Intended Usage

This package is **not designed for direct use by customers**. It acts as the foundation layer for other Stream SDKs and contains internal logic that is subject to change.

> If you're building an app with Stream, use [stream-chat-swift](https://github.com/GetStream/stream-chat-swift) or [stream-video-swift](https://github.com/GetStream/stream-video-swift) instead.

## ⚠️ Versioning Notice

This library does **not** follow semantic versioning. Breaking changes may be introduced at any time without warning. We reserve the right to refactor or remove functionality without deprecation periods.

## 📦 Installation

Since this SDK is internal, we do not recommend adding it directly to your project. It is primarily consumed as a dependency within other Stream SDKs via Swift Package Manager.

## 🪵 StreamLogsUI

`StreamLogsUI` is an in-app log viewer for debug builds and demo apps (iOS 16+). It has no dependencies, so it can be used with any logging library: forward log messages to `InMemoryLogStore.shared` and present the viewer.

```swift
import StreamLogsUI

// Presents the viewer as a sheet on top of the app.
LogViewer.present()

// Or present it when the device is shaken. Only enable this in debug builds.
LogViewer.presentsOnShake = true

// Or embed the list in your own navigation stack.
NavigationStack {
    LogListView()
}
```

### Forwarding logs

`LogEntry` only requires a level and a message. The other fields are optional, and `metadata` holds any extra key-value pairs, which are displayed and searchable. Besides the predefined levels, apps can define their own, e.g. `LogEntry.Level(severity: 45, name: "SECURITY")`.

<details>
<summary>StreamCore</summary>

```swift
import StreamCore
import StreamLogsUI

final class InMemoryLogDestination: BaseLogDestination, @unchecked Sendable {
    override func process(logDetails: LogDetails) {
        InMemoryLogStore.shared.append(LogEntry(
            date: logDetails.date,
            level: LogEntry.Level(logDetails.level),
            subsystems: LogSubsystem.allCases.filter { logDetails.subsystem.contains($0) }.map(\.description),
            threadName: logDetails.threadName,
            functionName: logDetails.functionName,
            fileName: logDetails.fileName,
            lineNumber: logDetails.lineNumber,
            message: logDetails.message,
            error: logDetails.error
        ))
    }
}

private extension LogEntry.Level {
    init(_ level: LogLevel) {
        switch level {
        case .debug: self = .debug
        case .info: self = .info
        case .warning: self = .warning
        case .error: self = .error
        }
    }
}

LogConfig.destinationTypes = [ConsoleLogDestination.self, InMemoryLogDestination.self]
```

</details>

<details>
<summary>swift-log</summary>

```swift
import Logging
import StreamLogsUI

struct InMemoryLogHandler: LogHandler {
    let label: String
    var logLevel: Logger.Level = .trace
    var metadata: Logger.Metadata = [:]

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        InMemoryLogStore.shared.append(LogEntry(
            level: LogEntry.Level(level),
            subsystems: [label],
            message: message.description,
            functionName: function,
            fileName: (file as NSString).lastPathComponent,
            lineNumber: line,
            metadata: self.metadata.merging(metadata ?? [:]) { $1 }.mapValues(\.description)
        ))
    }
}

private extension LogEntry.Level {
    init(_ level: Logger.Level) {
        switch level {
        case .trace: self = .trace
        case .debug: self = .debug
        case .info: self = .info
        case .notice: self = .notice
        case .warning: self = .warning
        case .error: self = .error
        case .critical: self = .critical
        }
    }
}

LoggingSystem.bootstrap { label in
    MultiplexLogHandler([StreamLogHandler.standardOutput(label: label), InMemoryLogHandler(label: label)])
}
```

</details>

<details>
<summary>CocoaLumberjack</summary>

```swift
import CocoaLumberjackSwift
import StreamLogsUI

final class InMemoryLogger: DDAbstractLogger {
    override func log(message logMessage: DDLogMessage) {
        InMemoryLogStore.shared.append(LogEntry(
            date: logMessage.timestamp,
            level: LogEntry.Level(logMessage.flag),
            message: logMessage.message,
            threadName: logMessage.threadName,
            functionName: logMessage.function,
            fileName: (logMessage.file as NSString).lastPathComponent,
            lineNumber: logMessage.line
        ))
    }
}

private extension LogEntry.Level {
    init(_ flag: DDLogFlag) {
        switch flag {
        case .error: self = .error
        case .warning: self = .warning
        case .info: self = .info
        case .debug: self = .debug
        default: self = .trace
        }
    }
}

DDLog.add(InMemoryLogger())
```

</details>

### Customization

- **Settings:** `LogSettings` holds the destinations shown in the settings screen, each with its own switch, level and subsystems. Use `apply(_:)` to rebuild your logger's destinations when they change.
- **Initial filter:** set `LogViewer.defaultFilter`, or pass a `LogFilter` to `LogViewer.present(filter:)` or `LogListView(filter:)`, to open the viewer with a level, subsystems or search text already applied.
- **Appearance:** `LogViewerAppearance` sets the color and icon of each level, and the subsystem and search highlight colors. Pass it to `LogViewer.present(appearance:)` or apply it with the `logViewerAppearance(_:)` modifier.
- **Storage:** `InMemoryLogStore` keeps the latest 5,000 entries by default. To keep entries elsewhere, implement `LogStore` and pass it to `LogViewer.present(store:)` or `LogListView(store:)`.