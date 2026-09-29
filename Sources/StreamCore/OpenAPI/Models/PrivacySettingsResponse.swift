//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class PrivacySettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var deliveryReceipts: DeliveryReceiptsResponse?
    public var readReceipts: ReadReceiptsResponse?
    public var typingIndicators: TypingIndicatorsResponse?

    public init(
        deliveryReceipts: DeliveryReceiptsResponse? = nil,
        readReceipts: ReadReceiptsResponse? = nil,
        typingIndicators: TypingIndicatorsResponse? = nil
    ) {
        self.deliveryReceipts = deliveryReceipts
        self.readReceipts = readReceipts
        self.typingIndicators = typingIndicators
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case deliveryReceipts = "delivery_receipts"
        case readReceipts = "read_receipts"
        case typingIndicators = "typing_indicators"
    }

    public static func == (lhs: PrivacySettingsResponse, rhs: PrivacySettingsResponse) -> Bool {
        lhs.deliveryReceipts == rhs.deliveryReceipts &&
            lhs.readReceipts == rhs.readReceipts &&
            lhs.typingIndicators == rhs.typingIndicators
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(deliveryReceipts)
        hasher.combine(readReceipts)
        hasher.combine(typingIndicators)
    }
}
