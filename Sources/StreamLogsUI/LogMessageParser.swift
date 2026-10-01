//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum LogMessageParser {
    static func curlCommand(in message: String) -> String? {
        guard let range = message.range(of: #"(?m)^\$?[ \t]*curl "#, options: .regularExpression) else {
            return nil
        }
        var command = message[range.lowerBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        if command.hasPrefix("$") {
            command = command.dropFirst().trimmingCharacters(in: .whitespaces)
        }
        return command
    }

    static func json(in message: String) -> String? {
        var searchStart = message.startIndex
        while let start = message[searchStart...].firstIndex(of: "{") {
            guard let end = closingBraceIndex(in: message, from: start) else { return nil }
            if let json = prettyPrintedJSON(String(message[start...end])) {
                return json
            }
            searchStart = message.index(after: end)
        }
        return nil
    }

    private static func closingBraceIndex(in text: String, from start: String.Index) -> String.Index? {
        var depth = 0
        var isInString = false
        var isEscaped = false
        for index in text[start...].indices {
            let character = text[index]
            if isInString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    isInString = false
                }
                continue
            }
            switch character {
            case "\"":
                isInString = true
            case "{":
                depth += 1
            case "}":
                depth -= 1
                if depth == 0 { return index }
            default:
                break
            }
        }
        return nil
    }

    private static func prettyPrintedJSON(_ text: String) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)),
            let data = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
        else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
}
