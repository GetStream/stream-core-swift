//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A parsed server response error.
public struct ErrorPayload: LocalizedError, Codable, CustomDebugStringConvertible, Equatable {
    private enum CodingKeys: String, CodingKey {
        case code
        case message
        case statusCode = "StatusCode"
    }
    
    /// An error code.
    public let code: Int
    /// A message.
    public let message: String
    /// An HTTP status code.
    public let statusCode: Int
    
    public var errorDescription: String? {
        "Error #\(code): \(message)"
    }
    
    public var debugDescription: String {
        "ServerErrorPayload(code: \(code), message: \"\(message)\", statusCode: \(statusCode)))."
    }

    public init(code: Int, message: String, statusCode: Int) {
        self.code = code
        self.message = message
        self.statusCode = statusCode
    }
}

extension ErrorPayload {
    /// Returns `true` if the code determines that the token is expired.
    public var isExpiredTokenError: Bool {
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

/// https://getstream.io/chat/docs/ios-swift/api_errors_response/
public enum StreamErrorCode {
    /// Usually returned when trying to perform an API call without a token.
    public static let accessKeyInvalid = 2
    public static let expiredToken = 40
    public static let notYetValidToken = 41
    public static let invalidTokenDate = 42
    public static let invalidTokenSignature = 43
}
