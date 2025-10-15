//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

open class DevicesAPI: DevicesAPIEndpoints, @unchecked Sendable {
    public var middlewares: [DefaultAPIClientMiddleware]
    var transport: DefaultAPITransport
    var basePath: String
    var jsonDecoder: JSONDecoder
    var jsonEncoder: JSONEncoder

    public init(
        basePath: String,
        transport: DefaultAPITransport,
        middlewares: [DefaultAPIClientMiddleware],
        jsonDecoder: JSONDecoder = JSONDecoder.default,
        jsonEncoder: JSONEncoder = JSONEncoder.default
    ) {
        self.basePath = basePath
        self.transport = transport
        self.middlewares = middlewares
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }

    func send<Response: Codable>(
        request: Request,
        deserializer: (Data) throws -> Response
    ) async throws -> Response {
        // TODO: make this a bit nicer and create an API error to make it easier to handle stuff
        func makeError(_ error: Error) -> Error {
            error
        }

        func wrappingErrors<R>(
            work: () async throws -> R,
            mapError: (Error) -> Error
        ) async throws -> R {
            do {
                return try await work()
            } catch {
                throw mapError(error)
            }
        }

        let (data, _) = try await wrappingErrors {
            var next: (Request) async throws -> (Data, URLResponse) = { _request in
                try await wrappingErrors {
                    try await self.transport.execute(request: _request)
                } mapError: { error in
                    makeError(error)
                }
            }
            for middleware in middlewares.reversed() {
                let tmp = next
                next = {
                    try await middleware.intercept(
                        $0,
                        next: tmp
                    )
                }
            }
            return try await next(request)
        } mapError: { error in
            makeError(error)
        }

        return try await wrappingErrors {
            try deserializer(data)
        } mapError: { error in
            makeError(error)
        }
    }

    func makeRequest(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String
    ) throws -> Request {
        let url = URL(string: basePath + uriPath)!
        return Request(
            url: url,
            method: .init(stringValue: httpMethod),
            queryParams: queryParams,
            headers: ["Content-Type": "application/json"]
        )
    }

    func makeRequest<T: Encodable>(
        uriPath: String,
        queryParams: [URLQueryItem] = [],
        httpMethod: String,
        request: T
    ) throws -> Request {
        var r = try makeRequest(uriPath: uriPath, queryParams: queryParams, httpMethod: httpMethod)
        r.body = try jsonEncoder.encode(request)
        return r
    }

    open func deleteDevice(id: String) async throws -> ModelResponse {
        let path = "/video/devices"
        
        let queryParams = APIHelper.mapValuesToQueryItems([
            "id": (wrappedValue: id.encodeToJSON(), isExplode: true)
            
        ])
        
        let urlRequest = try makeRequest(
            uriPath: path,
            queryParams: queryParams ?? [],
            httpMethod: "DELETE"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ModelResponse.self, from: $0)
        }
    }

    open func listDevices() async throws -> ListDevicesResponse {
        let path = "/video/devices"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "GET"
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ListDevicesResponse.self, from: $0)
        }
    }

    open func createDevice(createDeviceRequest: CreateDeviceRequest) async throws -> ModelResponse {
        let path = "/video/devices"
        
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: createDeviceRequest
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(ModelResponse.self, from: $0)
        }
    }
}

protocol DevicesAPIEndpoints {
    func deleteDevice(id: String) async throws -> ModelResponse
        
    func listDevices() async throws -> ListDevicesResponse
        
    func createDevice(createDeviceRequest: CreateDeviceRequest) async throws -> ModelResponse
}
