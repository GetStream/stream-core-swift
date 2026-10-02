//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum LogMessageParser {
    // Returns the start of a message longer than `maxLength`, ending at a line break when one is close to the limit,
    // or `nil` when the whole message fits.
    static func preview(of message: String, maxLength: Int = 3000) -> String? {
        guard let limit = message.index(message.startIndex, offsetBy: maxLength, limitedBy: message.endIndex),
              limit < message.endIndex else {
            return nil
        }
        let start = message[..<limit]
        let halfway = message.index(message.startIndex, offsetBy: maxLength / 2)
        if let lineBreak = start.lastIndex(of: "\n"), lineBreak >= halfway {
            return String(message[..<lineBreak])
        }
        return String(start)
    }

    // Splits a message into its lines, cutting lines longer than `maxLength` into several chunks.
    static func chunks(of message: String, maxLength: Int = 1000) -> [String] {
        message.split(separator: "\n", omittingEmptySubsequences: false).flatMap { line -> [String] in
            guard line.count > maxLength else { return [String(line)] }
            var chunks: [String] = []
            var start = line.startIndex
            while start < line.endIndex {
                let end = line.index(start, offsetBy: maxLength, limitedBy: line.endIndex) ?? line.endIndex
                chunks.append(String(line[start..<end]))
                start = end
            }
            return chunks
        }
    }

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
