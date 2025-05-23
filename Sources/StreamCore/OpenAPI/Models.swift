//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol JSONEncodable {
    func encodeToJSON() -> Any
}

/// An enum where the last case value can be used as a default catch-all.
protocol CaseIterableDefaultsLast: Decodable & CaseIterable & RawRepresentable
    where RawValue: Decodable, AllCases: BidirectionalCollection {}

extension CaseIterableDefaultsLast {
    /// Initializes an enum such that if a known raw value is found, then it is decoded.
    /// Otherwise the last case is used.
    /// - Parameter decoder: A decoder.
    public init(from decoder: Decoder) throws {
        if let value = try Self(rawValue: decoder.singleValueContainer().decode(RawValue.self)) {
            self = value
        } else if let lastValue = Self.allCases.last {
            self = lastValue
        } else {
            throw DecodingError.valueNotFound(
                Self.Type.self,
                .init(codingPath: decoder.codingPath, debugDescription: "CaseIterableDefaultsLast")
            )
        }
    }
}

/// A flexible type that can be encoded (`.encodeNull` or `.encodeValue`)
/// or not encoded (`.encodeNothing`). Intended for request payloads.
public enum NullEncodable<Wrapped: Hashable>: Hashable {
    case encodeNothing
    case encodeNull
    case encodeValue(Wrapped)
}

extension NullEncodable: Codable where Wrapped: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Wrapped.self) {
            self = .encodeValue(value)
        } else if container.decodeNil() {
            self = .encodeNull
        } else {
            self = .encodeNothing
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .encodeNothing: return
        case .encodeNull: try container.encodeNil()
        case let .encodeValue(wrapped): try container.encode(wrapped)
        }
    }
}

open class Response<T> {
    public let statusCode: Int
    public let header: [String: String]
    public let body: T
    public let bodyData: Data?

    public init(statusCode: Int, header: [String: String], body: T, bodyData: Data?) {
        self.statusCode = statusCode
        self.header = header
        self.body = body
        self.bodyData = bodyData
    }

    public convenience init(response: HTTPURLResponse, body: T, bodyData: Data?) {
        let rawHeader = response.allHeaderFields
        var header = [String: String]()
        for (key, value) in rawHeader {
            if let key = key.base as? String, let value = value as? String {
                header[key] = value
            }
        }
        self.init(statusCode: response.statusCode, header: header, body: body, bodyData: bodyData)
    }
}
