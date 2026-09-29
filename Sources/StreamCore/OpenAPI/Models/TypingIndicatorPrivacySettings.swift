//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class TypingIndicatorPrivacySettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var enabled: Bool

    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }

    public static func == (lhs: TypingIndicatorPrivacySettings, rhs: TypingIndicatorPrivacySettings) -> Bool {
        lhs.enabled == rhs.enabled
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
    }
}
