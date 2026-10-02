//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

// The session is only built when the file is shared, so that presenting the share menu stays cheap.
@available(iOS 16.0, *)
struct LogSessionFile: Transferable, Sendable {
    let entries: @Sendable () -> [LogEntry]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { file in
            try SentTransferredFile(file.write())
        }
    }

    func write() throws -> URL {
        let session = LogSession(entries: entries())
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StreamLogsUI", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(session.fileName)
        try session.encoded().write(to: url, options: .atomic)
        return url
    }
}

extension LogSession {
    // Reads a file picked by the user, which may be outside of the app sandbox.
    static func read(from url: URL) throws -> LogSession {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try LogSession(data: Data(contentsOf: url))
    }
}
