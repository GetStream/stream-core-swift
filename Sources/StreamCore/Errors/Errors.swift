//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A Client error.
open class ClientError: Error, ReflectiveStringConvertible, @unchecked Sendable {
    public struct Location: Equatable, Sendable {
        public let file: String
        public let line: Int
    }
    
    /// The file and line number which emitted the error.
    public let location: Location?
    
    private let message: String?

    /// An underlying error.
    public let underlyingError: Error?
    
    public let apiError: APIError?
    
    public var errorDescription: String? {
        if let apiError {
            apiError.message
        } else {
            underlyingError.map(String.init(describing:))
        }
    }
    
    /// Retrieve the localized description for this error.
    open var localizedDescription: String { message ?? errorDescription ?? "" }
    
    /// A client error based on an external general error.
    /// - Parameters:
    ///   - error: an external error.
    ///   - file: a file name source of an error.
    ///   - line: a line source of an error.
    public init(with error: Error? = nil, _ file: StaticString = #fileID, _ line: UInt = #line) {
        underlyingError = error
        message = error?.localizedDescription ?? nil
        location = .init(file: "\(file)", line: Int(line))
        if let aErr = error as? APIError {
            apiError = aErr
        } else {
            apiError = nil
        }
    }
    
    /// An error based on a message.
    /// - Parameters:
    ///   - message: an error message.
    ///   - file: a file name source of an error.
    ///   - line: a line source of an error.
    public init(_ message: String, _ file: StaticString = #fileID, _ line: UInt = #line) {
        self.message = message
        location = .init(file: "\(file)", line: Int(line))
        underlyingError = nil
        apiError = nil
    }
}

extension ClientError {
    /// An unexpected error.
    public final class Unexpected: ClientError, @unchecked Sendable {}

    /// An unknown error.
    public final class Unknown: ClientError, @unchecked Sendable {}

    /// Networking error.
    public final class NetworkError: ClientError, @unchecked Sendable {}

    /// Represents a network-related error indicating that the network is unavailable.
    public final class NetworkNotAvailable: ClientError, @unchecked Sendable {}

    /// Permissions error.
    public final class MissingPermissions: ClientError, @unchecked Sendable {}

    /// Invalid url error.
    public final class InvalidURL: ClientError, @unchecked Sendable {}
}

// This should probably live only in the test target since it's not "true" equatable
extension ClientError: Equatable {
    public static func == (lhs: ClientError, rhs: ClientError) -> Bool {
        type(of: lhs) == type(of: rhs)
            && String(describing: lhs.underlyingError) == String(describing: rhs.underlyingError)
            && String(describing: lhs.localizedDescription) == String(describing: rhs.localizedDescription)
    }
}

public extension ClientError {
    /// Returns `true` if underlaying error is `ErrorPayload` with code is inside invalid token codes range.
    var isInvalidTokenError: Bool {
        (underlyingError as? ErrorPayload)?.isInvalidTokenError == true
            || apiError?.isTokenExpiredError == true
    }
}

extension Error {
    var isRateLimitError: Bool {
        if let error = (self as? ClientError)?.underlyingError as? ErrorPayload,
           error.statusCode == 429 {
            return true
        }
        return false
    }
}

extension Error {
    public var isTokenExpiredError: Bool {
        if let error = self as? APIError, ClosedRange.tokenInvalidErrorCodes ~= error.code {
            return true
        }
        return false
    }
    
    public var hasClientErrors: Bool {
        if let apiError = self as? APIError,
           ClosedRange.clientErrorCodes ~= apiError.statusCode {
            return false
        }
        return true
    }
}

extension ClosedRange where Bound == Int {
    /// The error codes for token-related errors. Typically, a refreshed token is required to recover.
    public static let tokenInvalidErrorCodes: Self = 40...42
    
    /// The range of HTTP request status codes for client errors.
    static let clientErrorCodes: Self = 400...499
}

struct APIErrorContainer: Codable {
    let error: APIError
}

extension APIError: Error {}

/// https://getstream.io/chat/docs/ios-swift/api_errors_response/
enum StreamErrorCode {
    /// Usually returned when trying to perform an API call without a token.
    static let accessKeyInvalid = 2
    static let expiredToken = 40
    static let notYetValidToken = 41
    static let invalidTokenDate = 42
    static let invalidTokenSignature = 43
}
