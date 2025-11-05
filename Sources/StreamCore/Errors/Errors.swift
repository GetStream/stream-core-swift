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

extension ClientError {
    /// Returns `true` the stream code determines that the token is expired.
    public var isTokenExpiredError: Bool {
        apiError?.isTokenExpiredError == true
    }

    /// Returns `true` if underlaying error is `ErrorPayload` with code is inside invalid token codes range.
    public var isInvalidTokenError: Bool {
        apiError?.isInvalidTokenError == true
    }
}

extension ClientError {
    public class UnsupportedEventType: ClientError, @unchecked Sendable {
        override public var localizedDescription: String { "The incoming event type is not supported. Ignoring." }
    }
    
    public final class EventDecoding: ClientError, @unchecked Sendable {
        override init(_ message: String, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init(message, file, line)
        }

        public init<T>(missingValue: String, for type: T.Type, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init("`\(missingValue)` field can't be `nil` for the `\(type)` event.", file, line)
        }

        public init(missingValue: String, for eventTypeRaw: String, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init("`\(missingValue)` field can't be `nil` for the `\(eventTypeRaw)` event.", file, line)
        }

        public init(failedParsingValue: String, for eventTypeRaw: String, with error: Error, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init("`\(failedParsingValue)` failed to parse for the `\(eventTypeRaw)` event. Error: \(error)", file, line)
        }
    }
}

extension Error {
    var isRateLimitError: Bool {
        if let error = (self as? ClientError)?.apiError,
           error.statusCode == 429 {
            return true
        }
        return false
    }
}

extension Error {
    public var isTokenExpiredError: Bool {
        if let error = self as? APIError, error.isTokenExpiredError {
            return true
        }
        if let error = self as? ClientError, error.isTokenExpiredError {
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
    public static let tokenInvalidErrorCodes: Self = StreamErrorCode.notYetValidToken...StreamErrorCode.invalidTokenSignature

    /// The range of HTTP request status codes for client errors.
    public static let clientErrorCodes: Self = 400...499
}

extension APIError {
    /// Returns `true` if the code determines that the token is expired.
    public var isTokenExpiredError: Bool {
        code == StreamErrorCode.expiredToken
    }

    /// Returns `true` if code is within invalid token codes range.
    public var isInvalidTokenError: Bool {
        ClosedRange.tokenInvalidErrorCodes ~= code || code == StreamErrorCode.accessKeyInvalid
    }

    /// Returns `true` if status code is within client error codes range.
    public var isClientError: Bool {
        ClosedRange.clientErrorCodes ~= statusCode
    }
}

struct APIErrorContainer: Codable {
    let error: APIError
}

extension APIError: Error {}

/// https://getstream.io/chat/docs/ios-swift/api_errors_response/
public enum StreamErrorCode {
    /// Usually returned when trying to perform an API call without a token.
    public static let accessKeyInvalid = 2
    public static let expiredToken = 40
    public static let notYetValidToken = 41
    public static let invalidTokenDate = 42
    public static let invalidTokenSignature = 43
}
