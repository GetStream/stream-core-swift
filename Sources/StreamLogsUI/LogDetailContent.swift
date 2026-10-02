//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct LogDetailContent: Sendable {
    let rawText: String
    let rawPreview: String?
    let curlCommand: String?
    // The response body of HTTP requests, or the JSON found in other messages.
    let json: String?

    init(entry: LogEntry) {
        rawText = entry.rawText
        rawPreview = LogMessageParser.preview(of: rawText)

        let httpRequest = entry.httpRequest
        curlCommand = httpRequest?.curlCommand.flatMap(LogMessageParser.curlCommand(in:))
            ?? LogMessageParser.curlCommand(in: entry.message)

        if let httpRequest {
            json = httpRequest.responseBody.flatMap(LogMessageParser.json(in:))
        } else {
            json = LogMessageParser.json(in: entry.message)
        }
    }
}
