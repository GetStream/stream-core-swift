//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum EndpointPath: Codable {
    case uploadAttachment(type: String)
    
    var value: String {
        switch self {
        case let .uploadAttachment(type): "/api/v2/uploads/\(type)"
        }
    }
}
