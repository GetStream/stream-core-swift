//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
import Testing

struct MultipartFormData_Tests {
    @Test func `Encode uses the generated boundary by default`() {
        let encodedData = MultipartFormData(Data(), fileName: "attachment.bin").encode()
        let encodedString = String(decoding: encodedData, as: UTF8.self)
        let boundary = String(encodedString.dropFirst(2).prefix(21))

        #expect(boundary.hasPrefix("chat-"))
        #expect(boundary.dropFirst(5).allSatisfy { $0.isHexDigit })
        #expect(encodedString.hasSuffix("\r\n--\(boundary)--\r\n"))
    }

    @Test func `Encode uses the provided boundary`() {
        let payload = Data("content".utf8)
        let multipartFormData = MultipartFormData(
            payload,
            fileName: "attachment.bin",
            boundary: "test-boundary"
        )

        #expect(multipartFormData.boundary == "test-boundary")
        #expect(multipartFormData.encode() == expectedData(
            payload: payload,
            fileName: "attachment.bin",
            mimeType: nil,
            boundary: "test-boundary"
        ))
    }

    @Test func `Encode includes MIME type and preserves binary payload`() {
        let payload = Data([0x00, 0xff, 0x01])
        let multipartFormData = MultipartFormData(
            payload,
            fileName: "attachment.bin",
            mimeType: "application/octet-stream",
            boundary: "test-boundary"
        )

        #expect(multipartFormData.encode() == expectedData(
            payload: payload,
            fileName: "attachment.bin",
            mimeType: "application/octet-stream",
            boundary: "test-boundary"
        ))
    }

    @Test func `Encode omits MIME type header when no MIME type is provided`() {
        let payload = Data("content".utf8)
        let multipartFormData = MultipartFormData(payload, fileName: "attachment.bin", boundary: "test-boundary")

        #expect(multipartFormData.encode() == expectedData(
            payload: payload,
            fileName: "attachment.bin",
            mimeType: nil,
            boundary: "test-boundary"
        ))
    }

    private func expectedData(payload: Data, fileName: String, mimeType: String?, boundary: String) -> Data {
        var expected = Data("--\(boundary)\r\n".utf8)
        expected.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".utf8))

        if let mimeType {
            expected.append(Data("Content-Type: \(mimeType)\r\n".utf8))
        }

        expected.append(Data("\r\n".utf8))
        expected.append(payload)
        expected.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return expected
    }
}
