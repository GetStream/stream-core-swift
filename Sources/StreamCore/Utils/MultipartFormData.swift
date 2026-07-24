//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Encodes a file as multipart form data.
public struct MultipartFormData: Encodable, Sendable {
    private static let crlf = "\r\n"

    @usableFromInline static let defaultBoundary: String = String(
        format: "chat-%08x%08x",
        UInt32.random(in: 0...UInt32.max),
        UInt32.random(in: 0...UInt32.max)
    )

    private let data: Data
    private let fileName: String
    private let mimeType: String?

    /// The boundary used to separate multipart form data parts.
    public let boundary: String

    /// Creates multipart form data for a file.
    public init(_ data: Data, fileName: String, mimeType: String? = nil, boundary: String = Self.defaultBoundary) {
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
        self.boundary = boundary
    }

    /// Encodes the file as a multipart form data body.
    public func encode() -> Data {
        var data = "--\(boundary)\(Self.crlf)".data(using: .utf8, allowLossyConversion: false)!
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\(Self.crlf)")

        if let mimeType {
            data.append("Content-Type: \(mimeType)\(Self.crlf)")
        }

        data.append(Self.crlf)
        data.append(self.data)
        data.append("\(Self.crlf)--\(boundary)--\(Self.crlf)")

        return data
    }
}

private extension Data {
    mutating func append(_ string: String, encoding: String.Encoding = .utf8) {
        append(string.data(using: encoding, allowLossyConversion: false)!)
    }
}
