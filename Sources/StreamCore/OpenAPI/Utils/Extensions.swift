//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Bool: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension Float: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension Int: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension Int32: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension Int64: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension Double: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension Decimal: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension String: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension URL: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension UUID: JSONEncodable {
    public func encodeToJSON() -> Any { self }
}

extension RawRepresentable where RawValue: JSONEncodable {
    public func encodeToJSON() -> Any { rawValue }
}

private func encodeIfPossible<T>(_ object: T) -> Any {
    if let encodableObject = object as? JSONEncodable {
        encodableObject.encodeToJSON()
    } else {
        object
    }
}

extension Array: JSONEncodable {
    public func encodeToJSON() -> Any {
        map(encodeIfPossible)
    }
}

extension Set: JSONEncodable {
    public func encodeToJSON() -> Any {
        Array(self).encodeToJSON()
    }
}

extension Dictionary: JSONEncodable {
    public func encodeToJSON() -> Any {
        var dictionary = [AnyHashable: Any]()
        for (key, value) in self {
            dictionary[key] = encodeIfPossible(value)
        }
        return dictionary
    }
}

extension Data: JSONEncodable {
    public func encodeToJSON() -> Any {
        base64EncodedString(options: Data.Base64EncodingOptions())
    }
}

extension Date: JSONEncodable {
    public func encodeToJSON() -> Any {
        CodableHelper.dateFormatter.string(from: self)
    }
}

extension JSONEncodable where Self: Encodable {
    public func encodeToJSON() -> Any {
        guard let data = try? CodableHelper.jsonEncoder.encode(self) else {
            fatalError("Could not encode to json: \(self)")
        }
        return data.encodeToJSON()
    }
}
