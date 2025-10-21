//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserAuth: @unchecked Sendable, DefaultAPIClientMiddleware {
    public var tokenProvider: () -> String
    public var connectionId: () async throws -> String
    
    public init(tokenProvider: @escaping () -> String, connectionId: @escaping () async throws -> String) {
        self.tokenProvider = tokenProvider
        self.connectionId = connectionId
    }

    public func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        let connectionId = try await connectionId()
        if !connectionId.isEmpty {
            modifiedRequest.queryParams.append(
                .init(name: "connection_id", value: connectionId)
            )
        }
        modifiedRequest.headers["Authorization"] = tokenProvider()
        modifiedRequest.headers["stream-auth-type"] = "jwt"
        return try await next(modifiedRequest)
    }
}

public struct AnonymousAuth: DefaultAPIClientMiddleware {
    var token: String
    
    public init(token: String) {
        self.token = token
    }
    
    public func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        if !token.isEmpty {
            modifiedRequest.headers["Authorization"] = token
        }
        modifiedRequest.headers["stream-auth-type"] = "anonymous"
        return try await next(modifiedRequest)
    }
}

public struct DefaultParams: DefaultAPIClientMiddleware {
    let apiKey: String
    let xStreamClientHeader: String
    
    public init(apiKey: String, xStreamClientHeader: String) {
        self.apiKey = apiKey
        self.xStreamClientHeader = xStreamClientHeader
    }
    
    public func intercept(
        _ request: Request,
        next: (Request) async throws -> (Data, URLResponse)
    ) async throws -> (Data, URLResponse) {
        var modifiedRequest = request
        modifiedRequest.queryParams.append(.init(name: "api_key", value: apiKey))
        modifiedRequest.headers["X-Stream-Client"] = xStreamClientHeader
        modifiedRequest.headers["x-client-request-id"] = UUID().uuidString
        return try await next(modifiedRequest)
    }
}
