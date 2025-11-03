//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamCore
import XCTest

final class ConnectionStatus_Tests: XCTestCase {
    func test_wsConnectionState_isTranslatedCorrectly() {
        let testError = ClientError(with: TestError())

        let invalidTokenError = ClientError(
            with: APIError(
                code: ClosedRange.tokenInvalidErrorCodes.lowerBound,
                message: .unique,
                statusCode: .unique
            )
        )

        let pairs: [(WebSocketConnectionState, ConnectionStatus)] = [
            (.initialized, .initialized),
            (.connecting, .connecting),
            (.authenticating, .connecting),
            (.disconnected(source: .systemInitiated), .connecting),
            (.disconnected(source: .noPongReceived), .connecting),
            (.disconnected(source: .serverInitiated(error: nil)), .connecting),
            (.disconnected(source: .serverInitiated(error: testError)), .connecting),
            (.disconnected(source: .serverInitiated(error: invalidTokenError)), .disconnected(error: invalidTokenError)),
            (.connected(healthCheckInfo: HealthCheckInfo(connectionId: .unique)), .connected),
            (.disconnecting(source: .noPongReceived), .disconnecting),
            (.disconnecting(source: .serverInitiated(error: testError)), .disconnecting),
            (.disconnecting(source: .systemInitiated), .disconnecting),
            (.disconnecting(source: .userInitiated), .disconnecting),
            (.disconnected(source: .userInitiated), .disconnected(error: nil))
        ]

        pairs.forEach {
            XCTAssertEqual($1, ConnectionStatus(webSocketConnectionState: $0))
        }
    }
}
