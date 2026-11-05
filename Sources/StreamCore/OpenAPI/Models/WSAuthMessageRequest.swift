//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class WSAuthMessageRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var eventProtocol: Int?
    public var products: [String]?
    public var token: String
    public var userDetails: ConnectUserDetailsRequest

    public init(eventProtocol: Int? = nil, products: [String]? = nil, token: String, userDetails: ConnectUserDetailsRequest) {
        self.eventProtocol = eventProtocol
        self.products = products
        self.token = token
        self.userDetails = userDetails
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case eventProtocol = "event_protocol"
        case products
        case token
        case userDetails = "user_details"
    }
    
    public static func == (lhs: WSAuthMessageRequest, rhs: WSAuthMessageRequest) -> Bool {
        lhs.eventProtocol == rhs.eventProtocol &&
            lhs.products == rhs.products &&
            lhs.token == rhs.token &&
            lhs.userDetails == rhs.userDetails
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(eventProtocol)
        hasher.combine(products)
        hasher.combine(token)
        hasher.combine(userDetails)
    }
}
