//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol that defines values that can be used in filters.
///
/// This protocol is automatically conformed to by common Swift types like `String`, `Int`, `Bool`, etc.
public protocol FilterValue: Sendable {
    var rawJSON: RawJSON { get }
}

// MARK: - Supported Built-In Filter Values

extension Bool: FilterValue {
    public var rawJSON: RawJSON { .bool(self) }
}

extension Date: FilterValue {
    /// Dates are automatically converted to RFC3339 format when serialized.
    public var rawJSON: RawJSON { .string(RFC3339DateFormatter.string(from: self)) }
}

extension Double: FilterValue {
    public var rawJSON: RawJSON { .number(self) }
}

extension Float: FilterValue {
    public var rawJSON: RawJSON { .number(Double(self)) }
}

extension Int: FilterValue {
    public var rawJSON: RawJSON { .number(Double(self)) }
}

extension String: FilterValue {
    public var rawJSON: RawJSON { .string(self) }
}

extension URL: FilterValue {
    /// URLs are automatically converted to their absolute string representation when serialized.
    public var rawJSON: RawJSON { .string(absoluteString) }
}

extension Array: FilterValue where Element: FilterValue {
    public var rawJSON: RawJSON { .array(self.map(\.rawJSON)) }
}

extension Dictionary: FilterValue where Key == String, Value == RawJSON {
    public var rawJSON: RawJSON { .dictionary(self) }
}

extension Optional: FilterValue where Wrapped: FilterValue {
    public var rawJSON: RawJSON {
        guard let value = self else { return .nil }
        return value.rawJSON
    }
}
