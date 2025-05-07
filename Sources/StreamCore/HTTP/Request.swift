//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
    case patch = "PATCH"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"

    public init(stringValue: String) {
        guard let method = HTTPMethod(rawValue: stringValue.uppercased()) else {
            self = .get
            return
        }
        self = method
    }
}

public struct Request {
    public var url: URL
    public var method: HTTPMethod
    public var body: Data? = nil
    public var queryParams: [URLQueryItem] = []
    public var headers: [String: String] = [:]
    
    public init(url: URL, method: HTTPMethod, body: Data? = nil, queryParams: [URLQueryItem], headers: [String : String]) {
        self.url = url
        self.method = method
        self.body = body
        self.queryParams = queryParams
        self.headers = headers
    }

    public func urlRequest() throws -> URLRequest {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var existingQueryItems = urlComponents.queryItems ?? []
        existingQueryItems.append(contentsOf: queryParams)
        urlComponents.queryItems = existingQueryItems
        var urlRequest = URLRequest(url: urlComponents.url!)
        headers.forEach { (k, v) in
            urlRequest.setValue(v, forHTTPHeaderField: k)
        }
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body
        return urlRequest
    }
}

public protocol DefaultAPITransport: Sendable {
    func execute(request: Request) async throws -> (Data, URLResponse)
}

public protocol DefaultAPIClientMiddleware: Sendable {
    func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse)
}

public struct EmptyResponse: Codable {}
