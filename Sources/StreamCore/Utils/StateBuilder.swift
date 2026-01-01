//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A builder for objects requiring @MainActor.
public final class StateBuilder<State: Sendable>: Sendable {
    @MainActor private var builder: ((@Sendable @MainActor () -> State))?
    @MainActor private var _state: State?
    
    public init(builder: (@escaping @Sendable @MainActor () -> State)) {
        self.builder = builder
    }
    
    @MainActor public var state: State {
        if let _state { return _state }
        let state = builder!()
        _state = state
        // Release captured values in the closure
        builder = nil
        return state
    }
}
