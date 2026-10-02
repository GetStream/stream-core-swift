//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct LogDetailContent: Sendable {
    let rawText: String
    let rawPreview: String?
    let curlCommand: String?
    let jsonTree: LogJSONTree
    // The last JSON document, which is the response body of HTTP requests that have one.
    let json: String?

    init(entry: LogEntry) {
        rawText = entry.rawText
        rawPreview = LogMessageParser.preview(of: rawText)

        let httpRequest = entry.httpRequest
        curlCommand = httpRequest?.curlCommand.flatMap(LogMessageParser.curlCommand(in:))
            ?? LogMessageParser.curlCommand(in: entry.message)

        var documents: [(title: String, text: String)] = []
        if let httpRequest {
            if let body = httpRequest.requestBody {
                documents.append((LogEntry.MetadataKey.httpRequestBody.rawValue, body))
            }
            if let body = httpRequest.responseBody {
                documents.append((LogEntry.MetadataKey.httpResponseBody.rawValue, body))
            }
        } else if let json = LogMessageParser.json(in: entry.message) {
            documents.append(("JSON", json))
        }
        jsonTree = LogJSONTree(documents: documents)
        json = jsonTree.roots.last.map(jsonTree.jsonText(for:))
    }
}
