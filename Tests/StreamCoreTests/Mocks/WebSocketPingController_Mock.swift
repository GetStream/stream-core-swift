//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import XCTest

final class WebSocketPingController_Mock: WebSocketPingController, @unchecked Sendable {
    @Atomic var connectionStateDidChange_connectionStates: [WebSocketConnectionState] = []
    @Atomic var pongReceivedCount = 0

    override func connectionStateDidChange(_ connectionState: WebSocketConnectionState) {
        _connectionStateDidChange_connectionStates.mutate { $0.append(connectionState) }
        super.connectionStateDidChange(connectionState)
    }

    override func pongReceived() {
        pongReceivedCount += 1
        super.pongReceived()
    }
}
