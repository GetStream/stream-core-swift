//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Dictionary where Key == LogMetadataKey, Value == String {
    /// Creates the metadata of an HTTP request, with the HTTP keys like ``LogMetadataKey/httpMethod``.
    ///
    /// JSON bodies are pretty-printed, and bodies that are neither JSON nor text, like uploaded files, are left out.
    ///
    /// - Parameters:
    ///   - request: The request that was sent.
    ///   - response: The response that was received, if any. Its status code is added when it's an HTTP response.
    ///   - responseBody: The body of the response, if any.
    ///   - error: The error the request failed with, if any.
    ///   - session: The session that sent the request, whose additional headers are added to the cURL command.
    static func http(
        request: URLRequest,
        response: URLResponse? = nil,
        responseBody: Data? = nil,
        error: Error? = nil,
        session: URLSession? = nil
    ) -> Self {
        var metadata: Self = [
            .httpMethod: request.httpMethod ?? "GET",
            .httpURL: request.url?.absoluteString ?? "",
            .httpCURL: request.cURLRepresentation(in: session)
        ]
        metadata[.httpStatusCode] = (response as? HTTPURLResponse).map { String($0.statusCode) }
        metadata[.httpError] = error.map { "\($0)" }
        metadata[.httpRequestBody] = request.httpBody?.logDescription
        metadata[.httpResponseBody] = responseBody?.logDescription
        return metadata
    }
}

extension Data {
    // Pretty-printed JSON, or the text of other bodies, or `nil` when the data is empty or isn't text.
    var logDescription: String? {
        guard !isEmpty else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: self, options: .fragmentsAllowed),
              let json = try? JSONSerialization.data(
                  withJSONObject: object,
                  options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]
              ) else {
            return String(data: self, encoding: .utf8)
        }
        return String(decoding: json, as: UTF8.self)
    }
}
