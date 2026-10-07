//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamCore
import XCTest

final class ClientError_Tests: XCTestCase, @unchecked Sendable {
    func test_isInvalidTokenError_whenUnderlayingErrorIsInvalidToken_returnsTrue() {
        // Create error code withing `ErrorPayload.tokenInvalidErrorCodes` range
        let error = APIError(
            code: StreamErrorCode.invalidTokenDate,
            message: "Server message",
            statusCode: 401
        )

        // Assert `isInvalidTokenError` returns true
        XCTAssertTrue(error.isInvalidTokenError)

        // Create client error wrapping the error
        let clientError = ClientError(with: error)

        // Assert `isInvalidTokenError` returns true
        XCTAssertTrue(clientError.isInvalidTokenError)

        XCTAssertEqual(
            "\(clientError as Error)",
            """
            Type: ClientError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 21))
             - message: Optional("Server message")
             - underlyingError: Optional(Type: APIError
             - code: 42
             - message: Server message
             - statusCode: 401)
             - apiError: Optional(Type: APIError
             - code: 42
             - message: Server message
             - statusCode: 401)
            """
        )
    }

    func test_isInvalidTokenError_whenUnderlayingErrorIsNotInvalidToken_returnsFalse() {
        // Create error code outside `ErrorPayload.tokenInvalidErrorCodes` range
        let error = APIError(
            code: ClosedRange.tokenInvalidErrorCodes.lowerBound - 1,
            message: "Server message",
            statusCode: 401
        )

        // Assert `isInvalidTokenError` returns false
        XCTAssertFalse(error.isInvalidTokenError)

        // Create client error wrapping the error
        let clientError = ClientError(with: error)

        // Assert `isInvalidTokenError` returns false
        XCTAssertFalse(clientError.isInvalidTokenError)

        XCTAssertEqual(
            "\(clientError as Error)",
            """
            Type: ClientError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 56))
             - message: Optional("Server message")
             - underlyingError: Optional(Type: APIError
             - code: 40
             - message: Server message
             - statusCode: 401)
             - apiError: Optional(Type: APIError
             - code: 40
             - message: Server message
             - statusCode: 401)
            """
        )
    }

    func test_rateLimitError_isEphemeralError() {
        let errorPayload = APIError(
            code: 9,
            message: "Server message",
            statusCode: 429
        )

        let error = ClientError(with: errorPayload)

        // Assert `isRateLimitError` returns true
        XCTAssertTrue(error.isRateLimitError)

        XCTAssertEqual(
            "\(error as Error)",
            """
            Type: ClientError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 86))
             - message: Optional("Server message")
             - underlyingError: Optional(Type: APIError
             - code: 9
             - message: Server message
             - statusCode: 429)
             - apiError: Optional(Type: APIError
             - code: 9
             - message: Server message
             - statusCode: 429)
            """
        )
    }

    // MARK: - Bridged localized description

    func test_localizedDescription_whenCreatedWithMessage_bridgesMessage() {
        let subject = ClientError("Message")

        XCTAssertEqual((subject as Error).localizedDescription, "Message")
        XCTAssertEqual(((subject as Error) as NSError).localizedDescription, "Message")

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: ClientError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 112))
             - message: Optional("Message")
            """
        )
    }

    func test_localizedDescription_whenSubclassCreatedWithMessage_bridgesMessage() {
        let subject = ClientError.Unexpected("Message")

        XCTAssertEqual((subject as Error).localizedDescription, "Message")

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: Unexpected
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 128))
             - message: Optional("Message")
            """
        )
    }

    func test_localizedDescription_whenSubclassOverridesWithConstant_bridgesOverride() {
        let subject = ConstantDescriptionError()

        XCTAssertEqual((subject as Error).localizedDescription, "Constant description")

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: ConstantDescriptionError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 143))
            """
        )
    }

    func test_localizedDescription_whenSubclassInterpolatesErrorDescription_bridgesOverride() {
        let subject = InterpolatedDescriptionError(with: APIError(code: 4, message: "Server message", statusCode: 400))

        XCTAssertEqual((subject as Error).localizedDescription, "Interpolated: Server message")

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: InterpolatedDescriptionError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 157))
             - message: Optional("Server message")
             - underlyingError: Optional(Type: APIError
             - code: 4
             - message: Server message
             - statusCode: 400)
             - apiError: Optional(Type: APIError
             - code: 4
             - message: Server message
             - statusCode: 400)
            """
        )
    }

    func test_localizedDescription_whenSubclassHasLabeledInit_bridgesMessage() {
        let subject = LabeledInitError(id: "123")

        XCTAssertEqual((subject as Error).localizedDescription, "Item with id 123 does not exist")

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: LabeledInitError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 180))
             - message: Optional("Item with id 123 does not exist")
            """
        )
    }

    func test_localizedDescription_whenWrappingAPIError_returnsServerMessage() {
        let subject = ClientError(with: APIError(code: 4, message: "Server message", statusCode: 400))

        XCTAssertEqual(subject.localizedDescription, "Server message")
        XCTAssertEqual((subject as Error).localizedDescription, "Server message")

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: ClientError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 195))
             - message: Optional("Server message")
             - underlyingError: Optional(Type: APIError
             - code: 4
             - message: Server message
             - statusCode: 400)
             - apiError: Optional(Type: APIError
             - code: 4
             - message: Server message
             - statusCode: 400)
            """
        )
    }

    func test_localizedDescription_whenWrappingClientError_bridgesInnerDescription() {
        let subject = ClientError(with: ConstantDescriptionError())

        XCTAssertEqual(subject.localizedDescription, "Constant description")
        XCTAssertEqual((subject as Error).localizedDescription, "Constant description")

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: ClientError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 219))
             - message: Optional("Constant description")
             - underlyingError: Optional(Type: ConstantDescriptionError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 219)))
            """
        )
    }

    func test_localizedDescription_whenWrappingNSError_bridgesItsDescription() {
        let subject = ClientError(with: NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "NSError message"]))

        XCTAssertEqual((subject as Error).localizedDescription, "NSError message")

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: ClientError
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 237))
             - message: Optional("NSError message")
             - underlyingError: Optional(Error Domain=Test Code=1 "NSError message" UserInfo={NSLocalizedDescription=NSError message})
            """
        )
    }

    func test_localizedDescription_whenNoMessage_keepsDefaultBridgedDescription() {
        let subject = ClientError.Unknown()

        XCTAssertEqual(subject.localizedDescription, "")
        XCTAssertTrue((subject as Error).localizedDescription.contains("StreamCore.ClientError.Unknown error 1"))

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: Unknown
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 253))
            """
        )
    }

    func test_nsErrorBridging_keepsDefaultDomainAndCode() {
        let subject = ClientError.Unknown("Message")

        let nsError = (subject as Error) as NSError

        XCTAssertEqual(nsError.domain, "StreamCore.ClientError.Unknown")
        XCTAssertEqual(nsError.code, 1)

        XCTAssertEqual(
            "\(subject as Error)",
            """
            Type: Unknown
             - location: Optional(StreamCore.ClientError.Location(file: "StreamCoreTests/ClientError_Tests.swift", line: 268))
             - message: Optional("Message")
            """
        )
    }
}

private final class ConstantDescriptionError: ClientError, @unchecked Sendable {
    override var localizedDescription: String { "Constant description" }
}

private final class InterpolatedDescriptionError: ClientError, @unchecked Sendable {
    override var localizedDescription: String { "Interpolated: \(errorDescription ?? "nil")" }
}

private final class LabeledInitError: ClientError, @unchecked Sendable {
    init(id: String, _ file: StaticString = #fileID, _ line: UInt = #line) {
        super.init("Item with id \(id) does not exist", file, line)
    }
}
