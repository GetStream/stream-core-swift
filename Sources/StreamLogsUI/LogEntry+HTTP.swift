//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct LogHTTPRequest: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case informational(Int)
        case success(Int)
        case redirection(Int)
        case clientError(Int)
        case serverError(Int)
        case failed

        init(statusCode: Int) {
            switch statusCode {
            case ..<200: self = .informational(statusCode)
            case 200..<300: self = .success(statusCode)
            case 300..<400: self = .redirection(statusCode)
            case 400..<500: self = .clientError(statusCode)
            default: self = .serverError(statusCode)
            }
        }

        var code: Int? {
            switch self {
            case let .informational(code), let .success(code), let .redirection(code), let .clientError(code), let .serverError(code):
                return code
            case .failed:
                return nil
            }
        }

        var reasonPhrase: String {
            guard let code else { return "Failed" }
            if let phrase = Self.reasonPhrases[code] {
                return phrase
            }
            switch self {
            case .informational: return "Informational"
            case .success: return "Success"
            case .redirection: return "Redirection"
            case .clientError: return "Client Error"
            case .serverError, .failed: return "Server Error"
            }
        }

        private static let reasonPhrases: [Int: String] = [
            100: "Continue", 101: "Switching Protocols",
            200: "OK", 201: "Created", 202: "Accepted", 204: "No Content", 206: "Partial Content",
            301: "Moved Permanently", 302: "Found", 304: "Not Modified", 307: "Temporary Redirect", 308: "Permanent Redirect",
            400: "Bad Request", 401: "Unauthorized", 403: "Forbidden", 404: "Not Found", 405: "Method Not Allowed",
            408: "Request Timeout", 409: "Conflict", 410: "Gone", 413: "Content Too Large", 415: "Unsupported Media Type",
            422: "Unprocessable Content", 429: "Too Many Requests",
            500: "Internal Server Error", 501: "Not Implemented", 502: "Bad Gateway", 503: "Service Unavailable",
            504: "Gateway Timeout"
        ]
    }

    let method: String
    let url: String
    let status: Status?
    let error: String?
    let requestBody: String?
    let responseBody: String?
    let curlCommand: String?

    var path: String {
        guard let components = URLComponents(string: url), !components.path.isEmpty else { return url }
        return components.path
    }

    var host: String? {
        URLComponents(string: url)?.host
    }
}

extension LogEntry {
    var httpRequest: LogHTTPRequest? {
        guard let method = metadata[.httpMethod], let url = metadata[.httpURL] else { return nil }
        let error = metadata[.httpError]
        let status = metadata[.httpStatusCode]
            .flatMap { Int($0) }
            .map(LogHTTPRequest.Status.init(statusCode:))
        return LogHTTPRequest(
            method: method.uppercased(),
            url: url,
            status: status ?? (error == nil ? nil : .failed),
            error: error,
            requestBody: metadata[.httpRequestBody],
            responseBody: metadata[.httpResponseBody],
            curlCommand: metadata[.httpCURL]
        )
    }
}
