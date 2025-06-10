//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
///   let parent: ActivityInfo? { _parent.value as? ActivityInfo }
///   let _parent: BoxedAny?
/// }
/// ```
public struct BoxedAny: Sendable {
    public init?(_ value: (any Sendable)?) {
        guard value != nil else { return nil }
        self.value = value
    }

    public let value: any Sendable
}
