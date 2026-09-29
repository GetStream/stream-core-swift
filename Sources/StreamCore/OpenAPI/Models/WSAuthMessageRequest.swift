//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class WSAuthMessageRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var memberCustomInclude: [String]?
    public var products: [String]?
    public var token: String
    public var userDetails: ConnectUserDetailsRequest

    public init(memberCustomInclude: [String]? = nil, products: [String]? = nil, token: String, userDetails: ConnectUserDetailsRequest) {
        self.memberCustomInclude = memberCustomInclude
        self.products = products
        self.token = token
        self.userDetails = userDetails
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case memberCustomInclude = "member_custom_include"
        case products
        case token
        case userDetails = "user_details"
    }
    
    public static func == (lhs: WSAuthMessageRequest, rhs: WSAuthMessageRequest) -> Bool {
        lhs.memberCustomInclude == rhs.memberCustomInclude &&
            lhs.products == rhs.products &&
            lhs.token == rhs.token &&
            lhs.userDetails == rhs.userDetails
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(memberCustomInclude)
        hasher.combine(products)
        hasher.combine(token)
        hasher.combine(userDetails)
    }
}
