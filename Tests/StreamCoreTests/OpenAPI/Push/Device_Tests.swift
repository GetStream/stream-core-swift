//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

struct Device_Tests {
    @Test
    func hardwareId_survivesCodingAndDistinguishesDevices() throws {
        let data = Data(#"{"created_at":"2026-10-08T12:00:00.123456789Z","id":"token","push_provider":"apn","user_id":"user","hardware_id":"hardware-1"}"#.utf8)
        let subject = try JSONDecoder.streamCore.decode(Device.self, from: data)
        let encoded = try JSONEncoder.streamCore.encode(subject)
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(object["hardware_id"] as? String == "hardware-1")

        let otherData = Data(String(decoding: data, as: UTF8.self).replacingOccurrences(of: "hardware-1", with: "hardware-2").utf8)
        let other = try JSONDecoder.streamCore.decode(Device.self, from: otherData)
        #expect(subject != other)
        #expect(Set([subject, other]).count == 2)
    }
}
