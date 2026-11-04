//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

struct WSAuthMessageRequest_Tests {
    @Test
    func encode_withEventProtocolAndMemberCustomInclude_includesThem() throws {
        let subject = WSAuthMessageRequest(
            eventProtocol: 3,
            memberCustomInclude: ["role_label"],
            products: ["chat"],
            token: "token",
            userDetails: ConnectUserDetailsRequest(id: "user")
        )

        let object = try encodedObject(subject)

        #expect(object["event_protocol"] as? Int == 3)
        #expect(object["member_custom_include"] as? [String] == ["role_label"])
        #expect(object["products"] as? [String] == ["chat"])
        #expect(object["token"] as? String == "token")
    }

    @Test
    func encode_withoutEventProtocolAndMemberCustomInclude_omitsThem() throws {
        let subject = WSAuthMessageRequest(token: "token", userDetails: ConnectUserDetailsRequest(id: "user"))

        let object = try encodedObject(subject)

        #expect(object["event_protocol"] == nil)
        #expect(object["member_custom_include"] == nil)
    }

    private func encodedObject(_ subject: WSAuthMessageRequest) throws -> [String: Any] {
        let encoded = try JSONEncoder.streamCore.encode(subject)
        return try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    }
}
