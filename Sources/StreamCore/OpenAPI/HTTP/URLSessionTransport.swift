//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class URLSessionTransport: DefaultAPITransport, @unchecked Sendable {
    private let urlSession: URLSession
    private let xStreamClientHeader: String
    private var tokenProvider: UserTokenProvider?
    private let updateQueue: DispatchQueue = .init(
        label: "io.getStream.video.URLSessionClient",
        qos: .userInitiated
    )
    private(set) var onTokenUpdate: UserTokenUpdater?

    public init(
        urlSession: URLSession,
        xStreamClientHeader: String,
        tokenProvider: UserTokenProvider? = nil
    ) {
        self.urlSession = urlSession
        self.xStreamClientHeader = xStreamClientHeader
        self.tokenProvider = tokenProvider
    }

    func setTokenUpdater(_ tokenUpdater: @escaping UserTokenUpdater) {
        updateQueue.async { [weak self] in
            self?.onTokenUpdate = tokenUpdater
        }
    }
    
    func update(tokenProvider: @escaping UserTokenProvider) {
        updateQueue.async { [weak self] in
            self?.tokenProvider = tokenProvider
        }
    }

    public func refreshToken() async throws -> UserToken {
        try await withCheckedThrowingContinuation { continuation in
            tokenProvider? { result in
                switch result {
                case let .success(token):
                    continuation.resume(returning: token)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func execute(request: URLRequest) async throws -> (Data, URLResponse) {
        try await executeTask(retryPolicy: .fastAndSimple) {
            do {
                return try await perform(request)
            } catch {
                if error.isTokenExpiredError && tokenProvider != nil {
                    log.debug("Refreshing user token", subsystems: .httpRequests)
                    let token = try await refreshToken()
                    if let onTokenUpdate {
                        onTokenUpdate(token)
                    }
                    let updated = update(request: request, with: token.rawValue)
                    return try await perform(updated)
                } else {
                    throw error
                }
            }
        }
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.dataTask(with: request) { [urlSession] data, response, error in
                let result = Self.result(request: request, data: data, response: response, error: error)
                Self.logResponse(result, request: request, data: data, response: response, session: urlSession)
                continuation.resume(with: result)
            }
            task.resume()
        }
    }

    private func update(request: URLRequest, with token: String) -> URLRequest {
        var updated = request
        updated.setValue(token, forHTTPHeaderField: "authorization")
        return updated
    }
    
    private static func result(
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> Result<(Data, URLResponse), Error> {
        if let error {
            return .failure(error)
        }
        if let response = response as? HTTPURLResponse, response.statusCode >= 400 || data == nil {
            return .failure(apiError(from: data, response: response))
        }
        guard let data, let response else {
            return .failure(
                ClientError.NetworkError(
                    "HTTP request failed without response data, URL: \(request.url?.absoluteString ?? "-")"
                )
            )
        }
        return .success((data, response))
    }

    private static func logResponse(
        _ result: Result<(Data, URLResponse), Error>,
        request: URLRequest,
        data: Data?,
        response: URLResponse?,
        session: URLSession
    ) {
        var error: Error?
        if case let .failure(failure) = result {
            error = failure
        }
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        log.log(
            logLevel(for: error),
            message: request.logMessage(status: statusCode.map(String.init) ?? "FAILED"),
            subsystems: .httpRequests,
            error: nil,
            attachment: HTTPLogAttachment(request: request, response: response, responseBody: data, error: error, session: session)
        )
    }

    private static func logLevel(for error: Error?) -> LogLevel {
        guard let error else { return .debug }
        if error.isTokenExpiredError {
            return .info
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, [NSURLErrorCancelled, NSURLErrorNetworkConnectionLost].contains(nsError.code) {
            return .info
        }
        return .error
    }

    private static func apiError(from data: Data?, response: HTTPURLResponse) -> Error {
        guard let data else {
            return ClientError.NetworkError(
                "HTTP status code: \(response.statusCode) URL: \(response.url?.absoluteString ?? "-")"
            )
        }

        do {
            return try JSONDecoder.streamCore.decode(APIError.self, from: data)
        } catch {
            return ClientError.NetworkError(response.description)
        }
    }

    public func execute(request: Request) async throws -> (Data, URLResponse) {
        var clone = request
        clone.headers["Content-Type"] = "application/json"
        clone.headers["X-Stream-Client"] = xStreamClientHeader
        return try await execute(request: clone.urlRequest())
    }
}

extension URLRequest {
    func logMessage(status: String) -> String {
        "\(status) \(httpMethod ?? "GET") \(url?.path ?? "")"
    }
}
