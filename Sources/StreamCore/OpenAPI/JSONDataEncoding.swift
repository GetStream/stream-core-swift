//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public struct JSONDataEncoding {

    // MARK: Properties

    private static let jsonDataKey = "jsonData"

    // MARK: Encoding

    /// Creates a URL request by encoding parameters and applying them onto an existing request.
    ///
    /// - parameter urlRequest: The request to have parameters applied.
    /// - parameter parameters: The parameters to apply. This should have a single key/value
    ///                         pair with "jsonData" as the key and a Data object as the value.
    ///
    /// - throws: An `Error` if the encoding process encounters an error.
    ///
    /// - returns: The encoded request.
    public func encode(_ urlRequest: URLRequest, with parameters: [String: Any]?) -> URLRequest {
        var urlRequest = urlRequest

        guard let jsonData = parameters?[JSONDataEncoding.jsonDataKey] as? Data, !jsonData.isEmpty else {
            return urlRequest
        }

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        urlRequest.httpBody = jsonData

        return urlRequest
    }

    public static func encodingParameters(jsonData: Data?) -> [String: Any]? {
        var returnedParams: [String: Any]?
        if let jsonData = jsonData, !jsonData.isEmpty {
            var params: [String: Any] = [:]
            params[jsonDataKey] = jsonData
            returnedParams = params
        }
        return returnedParams
    }
}
