//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Erase type for structs which recursively contain themselves.
///
/// Example:
/// ```swift
/// struct ActivityInfo {
///   let parent: ActivityInfo?
/// }
/// ```
/// Can be written as:
/// ```swift
/// struct ActivityInfo {
///   let parent: ActivityInfo? { _parent.getValue() }
///   let _parent: BoxedAny?
/// }
/// ```
public struct BoxedAny: Equatable, Sendable {
    private let value: any Equatable & Sendable
    private let isEqual: @Sendable (any Equatable & Sendable) -> Bool
    
    public init<T: Equatable & Sendable>(_ value: T) {
        self.value = value
        isEqual = { other in
            guard let otherValue = other as? T else { return false }
            return value == otherValue
        }
    }
    
    public func getValue<T>() -> T? {
        value as? T
    }
    
    public static func == (lhs: BoxedAny, rhs: BoxedAny) -> Bool {
        lhs.isEqual(rhs.value)
    }
}
