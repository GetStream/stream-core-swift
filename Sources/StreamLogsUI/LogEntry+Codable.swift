//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension LogEntry: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case level
        case subsystems
        case message
        case threadName
        case functionName
        case fileName
        case lineNumber
        case metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        self.init(
            id: try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID(),
            date: try container.decode(Date.self, forKey: .date),
            level: try container.decode(Level.self, forKey: .level),
            subsystems: try container.decodeIfPresent([String].self, forKey: .subsystems) ?? [],
            message: try container.decode(String.self, forKey: .message),
            threadName: try container.decodeIfPresent(String.self, forKey: .threadName),
            functionName: try container.decodeIfPresent(String.self, forKey: .functionName),
            fileName: try container.decodeIfPresent(String.self, forKey: .fileName),
            lineNumber: try container.decodeIfPresent(UInt.self, forKey: .lineNumber),
            metadata: Dictionary(uniqueKeysWithValues: metadata.map { (MetadataKey(rawValue: $0.key), $0.value) })
        )
    }

    // Metadata is encoded as an object, as dictionaries with non-string keys are encoded as arrays.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(level, forKey: .level)
        if !subsystems.isEmpty {
            try container.encode(subsystems, forKey: .subsystems)
        }
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(threadName, forKey: .threadName)
        try container.encodeIfPresent(functionName, forKey: .functionName)
        try container.encodeIfPresent(fileName, forKey: .fileName)
        try container.encodeIfPresent(lineNumber, forKey: .lineNumber)
        if !metadata.isEmpty {
            let metadata = Dictionary(uniqueKeysWithValues: metadata.map { ($0.key.rawValue, $0.value) })
            try container.encode(metadata, forKey: .metadata)
        }
    }
}

extension LogEntry.Level: Codable {
    private enum CodingKeys: String, CodingKey {
        case severity
        case name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            severity: container.decode(Int.self, forKey: .severity),
            name: container.decode(String.self, forKey: .name)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(severity, forKey: .severity)
        try container.encode(name, forKey: .name)
    }
}

extension LogEntry.MetadataKey: Codable {
    public init(from decoder: Decoder) throws {
        try self.init(rawValue: decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
