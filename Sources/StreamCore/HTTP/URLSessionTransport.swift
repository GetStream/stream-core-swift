//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    func refreshToken() async throws -> UserToken {
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
        log.debug(request.cURLRepresentation(in: urlSession))
        return try await executeTask(retryPolicy: .fastAndSimple) {
            do {
                return try await execute(request: request, isRetry: false)
            } catch {
                if error.isTokenExpiredError && tokenProvider != nil {
                    log.debug("Refreshing user token", subsystems: .httpRequests)
                    let token = try await refreshToken()
                    if let onTokenUpdate = onTokenUpdate {
                        onTokenUpdate(token)
                    }
                    let updated = update(request: request, with: token.rawValue)
                    log.debug("Retrying failed request \(updated) with new token", subsystems: .httpRequests)
                    return try await execute(request: updated, isRetry: true)
                } else {
                    throw error
                }
            }
        }
    }

    private func execute(request: URLRequest, isRetry: Bool) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if response.statusCode >= 400 || data == nil {
                        continuation.resume(throwing: Self.apiError(from: data, response: response))
                        return
                    }
                }
                guard let data = data, let response = response else {
                    continuation.resume(
                        throwing: ClientError.NetworkError(
                            "HTTP request failed without response data, URL: \(request.url?.absoluteString ?? "-")"
                        )
                    )
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }

    private func update(request: URLRequest, with token: String) -> URLRequest {
        var updated = request
        updated.setValue(token, forHTTPHeaderField: "authorization")
        return updated
    }
    
    private static func apiError(from data: Data?, response: HTTPURLResponse) -> Error {
        guard let data = data else {
            return ClientError.NetworkError(
                "HTTP status code: \(response.statusCode) URL: \(response.url?.absoluteString ?? "-")"
            )
        }

        do {
            return try JSONDecoder.default.decode(APIError.self, from: data)
        } catch {
            return ClientError.NetworkError(response.description)
        }
    }

    public func execute(request: Request) async throws -> (Data, URLResponse) {
        var clone = request
        clone.headers["Content-Type"] = "application/json"
        clone.headers["X-Stream-Client"] = xStreamClientHeader
        do {
            return try await execute(request: clone.urlRequest())
        } catch {
            log.error("HTTP request failed: \(request.url.absoluteString)", subsystems: .httpRequests, error: error)
            throw error
        }
    }
}
