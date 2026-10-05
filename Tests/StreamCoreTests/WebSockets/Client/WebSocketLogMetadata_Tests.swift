//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

struct WebSocketLogMetadata_Tests {
    @Test func jsonPayloadIsPrettyPrintedWithItsEventType() {
        let data = Data(#"{"type":"message.new","cid":"messaging:general"}"#.utf8)

        let metadata = data.webSocketLogMetadata(payloadKey: .webSocketReceivedPayload)

        #expect(metadata == [
            .webSocketEventType: "message.new",
            .webSocketReceivedPayload: "{\n  \"cid\" : \"messaging:general\",\n  \"type\" : \"message.new\"\n}"
        ])
    }

    @Test func jsonPayloadWithoutTypeHasNoEventType() {
        let data = Data(#"{"token":"abc"}"#.utf8)

        let metadata = data.webSocketLogMetadata(payloadKey: .webSocketSentPayload)

        #expect(metadata == [.webSocketSentPayload: "{\n  \"token\" : \"abc\"\n}"])
    }

    @Test func textPayloadIsKeptAsIs() {
        let metadata = Data("ping".utf8).webSocketLogMetadata(payloadKey: .webSocketReceivedPayload)

        #expect(metadata == [.webSocketReceivedPayload: "ping"])
    }

    @Test func binaryPayloadIsDescribedByItsSize() {
        let metadata = Data([0xff, 0xfe, 0x00]).webSocketLogMetadata(payloadKey: .webSocketReceivedPayload)

        #expect(metadata == [.webSocketReceivedPayload: "<3 bytes>"])
    }
}
