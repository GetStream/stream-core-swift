//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A set of log entries with information about the app and device that recorded them.
///
/// Sessions are exported and imported as JSON files from ``LogListView``, so that logs can be shared and inspected
/// on another device. Use ``encoded()`` and ``init(data:)`` to read and write the same format.
public struct LogSession: Codable, Sendable {
    /// The version of the file format written by ``encoded()``.
    public static let currentFormatVersion = 1

    /// The version of the file format the session was read from.
    public let formatVersion: Int
    public let exportDate: Date
    public let appName: String?
    public let appIdentifier: String?
    public let appVersion: String?
    public let appBuild: String?
    /// The operating system of the device, e.g. `iOS 26.0.1`.
    public let systemVersion: String?
    /// The model identifier of the device, e.g. `iPhone17,1`.
    public let deviceModel: String?
    /// The entries, oldest first.
    public let entries: [LogEntry]

    /// Creates a session with the given entries, described by default with the current app and device.
    public init(
        entries: [LogEntry],
        exportDate: Date = Date(),
        appName: String? = LogSession.currentAppName,
        appIdentifier: String? = Bundle.main.bundleIdentifier,
        appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        appBuild: String? = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
        systemVersion: String? = LogSession.currentSystemVersion,
        deviceModel: String? = LogSession.currentDeviceModel
    ) {
        formatVersion = Self.currentFormatVersion
        self.exportDate = exportDate
        self.appName = appName
        self.appIdentifier = appIdentifier
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.systemVersion = systemVersion
        self.deviceModel = deviceModel
        self.entries = entries
    }

    /// Reads a session from the JSON data written by ``encoded()``.
    public init(data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = LogSessionDateFormatter.shared.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO 8601 date: \(string)")
            }
            return date
        }
        self = try decoder.decode(Self.self, from: data)
    }

    /// Writes the session as JSON, with ISO 8601 dates in milliseconds precision.
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(LogSessionDateFormatter.shared.string(from: date))
        }
        return try encoder.encode(self)
    }
}

public extension LogSession {
    /// The display name of the current app.
    static var currentAppName: String? {
        let info = Bundle.main.infoDictionary
        return info?["CFBundleDisplayName"] as? String ?? info?["CFBundleName"] as? String
    }

    /// The operating system of the current device, e.g. `iOS 26.0.1`.
    static var currentSystemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "iOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// The model identifier of the current device, e.g. `iPhone17,1`.
    static var currentDeviceModel: String? {
        if let simulatorModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModel
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
        return machine.isEmpty ? nil : machine
    }
}

extension LogSession {
    // e.g. `DemoApp Logs 2026-10-02 14.30.05.json`
    var fileName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let name = [appName, "Logs", formatter.string(from: exportDate)].compactMap { $0 }.joined(separator: " ")
        return "\(name.replacingOccurrences(of: "/", with: "-")).json"
    }

    // e.g. `DemoApp 5.0 (123) · iOS 26.0.1 · iPhone17,1`
    var sourceDescription: String {
        let version = [appVersion, appBuild.map { "(\($0))" }].compactMap { $0 }.joined(separator: " ")
        let app = [appName, version.isEmpty ? nil : version].compactMap { $0 }.joined(separator: " ")
        return [app.isEmpty ? nil : app, systemVersion, deviceModel].compactMap { $0 }.joined(separator: " · ")
    }
}

// `ISO8601DateFormatter` is thread-safe.
private final class LogSessionDateFormatter: @unchecked Sendable {
    static let shared = LogSessionDateFormatter()

    private let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let formatter = ISO8601DateFormatter()

    func string(from date: Date) -> String {
        fractionalSecondsFormatter.string(from: date)
    }

    func date(from string: String) -> Date? {
        fractionalSecondsFormatter.date(from: string) ?? formatter.date(from: string)
    }
}
