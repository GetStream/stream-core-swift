//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CreateDeviceRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public enum PushProvider: String, Sendable, Codable, CaseIterable {
        case apn
        case firebase
        case huawei
        case xiaomi
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    public var hardwareId: String?
    public var id: String
    public var pushProvider: PushProvider
    public var pushProviderName: String?
    public var voipToken: Bool?

    public init(hardwareId: String? = nil, id: String, pushProvider: PushProvider, pushProviderName: String? = nil, voipToken: Bool? = nil) {
        self.hardwareId = hardwareId
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
        self.voipToken = voipToken
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hardwareId = "hardware_id"
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case voipToken = "voip_token"
    }
    
    public static func == (lhs: CreateDeviceRequest, rhs: CreateDeviceRequest) -> Bool {
        lhs.hardwareId == rhs.hardwareId &&
            lhs.id == rhs.id &&
            lhs.pushProvider == rhs.pushProvider &&
            lhs.pushProviderName == rhs.pushProviderName &&
            lhs.voipToken == rhs.voipToken
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hardwareId)
        hasher.combine(id)
        hasher.combine(pushProvider)
        hasher.combine(pushProviderName)
        hasher.combine(voipToken)
    }
}
