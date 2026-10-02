//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct LogDetailContent: Sendable {
    let rawText: String
    // The lines of the raw text, with long lines cut into several chunks.
    let rawChunks: [String]
    // The number of chunks shown before the raw text is expanded, or `nil` when the whole text fits.
    let rawPreviewChunkCount: Int?
    let curlCommand: String?
    let jsonTree: LogJSONTree
    // The last JSON document, which is the response body of HTTP requests and the payload of WebSocket messages.
    let json: String?

    init(entry: LogEntry) {
        rawText = entry.rawText
        rawChunks = LogMessageParser.chunks(of: rawText)
        rawPreviewChunkCount = LogMessageParser.preview(of: rawText).map { LogMessageParser.chunks(of: $0).count }

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
        } else if let webSocketMessage = entry.webSocketMessage {
            documents.append((webSocketMessage.payloadKey.rawValue, webSocketMessage.payload))
        } else if let json = LogMessageParser.json(in: entry.message) {
            documents.append(("JSON", json))
        }
        jsonTree = LogJSONTree(documents: documents)
        json = jsonTree.roots.last.map(jsonTree.jsonText(for:))
    }

    var copyOptions: [LogCopyOption] {
        let options: [(title: String, text: String?)] = [("Raw", rawText), ("cURL", curlCommand), ("JSON", json)]
        return options.compactMap { option in
            option.text.map { LogCopyOption(title: option.title, text: $0) }
        }
    }
}

struct LogCopyOption: Identifiable, Equatable, Sendable {
    let title: String
    let text: String

    var id: String { title }
}
