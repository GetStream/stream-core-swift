//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object responsible for handling incoming URL request response and decoding it.
public protocol RequestDecoder: Sendable {
    /// Decodes an incoming URL request response.
    ///
    /// - Parameters:
    ///   - data: The incoming data.
    ///   - response: The response object from the network.
    ///   - error: An error object returned by the data task.
    ///
    /// - Throws: An error if the decoding fails.
    func decodeRequestResponse<ResponseType: Decodable>(data: Data?, response: URLResponse?, error: Error?) throws -> ResponseType
}

/// The default implementation of `RequestDecoder`.
public struct DefaultRequestDecoder: RequestDecoder {
    
    public init() {}
    
    public func decodeRequestResponse<ResponseType: Decodable>(data: Data?, response: URLResponse?, error: Error?) throws -> ResponseType {
        // Handle the error case
        guard error == nil else {
            let error = error!
            switch (error as NSError).code {
            case NSURLErrorCancelled:
                log.info("The request was cancelled.", subsystems: .httpRequests)
            case NSURLErrorNetworkConnectionLost:
                log.info("The network connection was lost.", subsystems: .httpRequests)
            default:
                log.error(error, subsystems: .httpRequests)
            }

            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.Unexpected("Expecting `HTTPURLResponse` but received: \(response?.description ?? "nil").")
        }

        guard let data = data, !data.isEmpty else {
            throw ClientError.ResponseBodyEmpty()
        }

        guard httpResponse.statusCode < 300 else {
            let serverError: ErrorPayload
            do {
                serverError = try JSONDecoder.default.decode(ErrorPayload.self, from: data)
            } catch {
                throw ClientError.Unknown("Unknown error. Server response: \(httpResponse).")
            }

            if serverError.isExpiredTokenError {
                log.info("Request failed because of an expired token.", subsystems: .httpRequests)
                throw ClientError.ExpiredToken()
            }

            throw ClientError(with: serverError)
        }

        if let responseAsData = data as? ResponseType {
            return responseAsData
        }

        do {
            let decodedPayload = try JSONDecoder.default.decode(ResponseType.self, from: data)
            return decodedPayload
        } catch {
            log.error(error, subsystems: .httpRequests)
            throw error
        }
    }
}

extension ClientError {
    final class ExpiredToken: ClientError, @unchecked Sendable {}
    final class RefreshingToken: ClientError, @unchecked Sendable {}
    final class TokenRefreshed: ClientError, @unchecked Sendable {}
    final class ConnectionError: ClientError, @unchecked Sendable {}
    final class ResponseBodyEmpty: ClientError, @unchecked Sendable {
        override var localizedDescription: String { "Response body is empty." }
    }

    static let temporaryErrors: Set<Int> = [
        NSURLErrorCancelled,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorTimedOut,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorNotConnectedToInternet,
        NSURLErrorBadServerResponse,
        NSURLErrorUserCancelledAuthentication,
        NSURLErrorCannotLoadFromNetwork,
        NSURLErrorDataNotAllowed
    ]

    // returns true if the error is related to a temporary condition
    // you can use this to check if it makes sense to retry an API call
    static func isEphemeral(error: Error) -> Bool {
        if temporaryErrors.contains((error as NSError).code) {
            return true
        }

        return false
    }
}


extension ErrorPayload {
    /// Returns `true` if the code determines that the token is expired.
    var isExpiredTokenError: Bool {
        code == StreamErrorCode.expiredToken
    }
}

/// https://getstream.io/chat/docs/ios-swift/api_errors_response/
enum StreamErrorCode {
    /// Usually returned when trying to perform an API call without a token.
    static let accessKeyInvalid = 2
    static let expiredToken = 40
    static let notYetValidToken = 41
    static let invalidTokenDate = 42
    static let invalidTokenSignature = 43
}
