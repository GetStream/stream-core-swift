//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension URLRequest {
    /// Gives cURL representation of the request for an easy API request reproducibility in Terminal.
    /// - Parameter urlSession: The URLSession handling the request.
    /// - Returns: cURL representation of the URLRequest.
    func cURLRepresentation(in urlSession: URLSession?) -> String {
        guard let url, let httpMethod else { return "$ curl failed to create" }
        var cURL = [String]()
        cURL.append("$ curl -v")
        cURL.append("-X \(httpMethod)")
        
        var allHeaders = [String: String]()
        if let additionalHeaders = urlSession?.configuration.httpAdditionalHeaders as? [String: String] {
            allHeaders.merge(additionalHeaders, uniquingKeysWith: { _, new in new })
        }
        if let allHTTPHeaderFields {
            allHeaders.merge(allHTTPHeaderFields, uniquingKeysWith: { _, new in new })
        }
        cURL.append(contentsOf: allHeaders
            .sorted { $0.key < $1.key }
            .map { name, value in
                let escapedValue = Self.loggedValue(ofHeader: name, value).replacingOccurrences(of: "\"", with: "\\\"")
                return "-H \"\(name): \(escapedValue)\""
            }
        )
        if let httpBody {
            let httpBodyString = String(decoding: httpBody, as: UTF8.self)
            let escapedBody = httpBodyString
                .replacingOccurrences(of: "\\\"", with: "\\\\\"")
                .replacingOccurrences(of: "\"", with: "\\\"")
            cURL.append("-d \"\(escapedBody)\"")
        }
        let urlString = url.absoluteString
            .replacingOccurrences(of: "$", with: "%24") // encoded JSON payload
        cURL.append("\"\(urlString)\"")
        return cURL.joined(separator: " \\\n\t")
    }

    func redactingCredentialHeaders() -> URLRequest {
        var request = self
        for name in (allHTTPHeaderFields ?? [:]).keys where Self.isCredentialHeader(name) {
            request.setValue(LogRedaction.redactedValue, forHTTPHeaderField: name)
        }
        return request
    }

    private static let credentialHeaderFields: Set<String> = ["authorization", "proxy-authorization", "cookie"]

    private static func isCredentialHeader(_ name: String) -> Bool {
        credentialHeaderFields.contains(name.lowercased())
    }

    private static func loggedValue(ofHeader name: String, _ value: String) -> String {
        isCredentialHeader(name) ? LogRedaction.redactedValue : value
    }
}
