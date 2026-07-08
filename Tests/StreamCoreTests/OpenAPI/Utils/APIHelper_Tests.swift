//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamCore
import Testing

struct APIHelper_Tests {
    // MARK: - escapedPathItem

    @Test("Plain string with only allowed characters passes through unchanged")
    func escapedPathItem_plainString() {
        #expect(APIHelper.escapedPathItem("simple-id_123.~") == "simple-id_123.~")
    }

    @Test("Characters disallowed in a path are percent-encoded")
    func escapedPathItem_encodesDisallowedCharacters() {
        #expect(APIHelper.escapedPathItem("a b") == "a%20b")
        #expect(APIHelper.escapedPathItem("a#b") == "a%23b")
        #expect(APIHelper.escapedPathItem("a?b") == "a%3Fb")
        #expect(APIHelper.escapedPathItem("100%") == "100%25")
        // ":" is not in .urlPathAllowed, so a channel CID's separator is encoded.
        #expect(APIHelper.escapedPathItem("messaging:general") == "messaging%3Ageneral")
    }

    @Test("Characters allowed in a URL path are not encoded")
    func escapedPathItem_keepsPathAllowedCharacters() {
        // ".urlPathAllowed" membership is OS-version dependent: iOS 15/16 encode
        // some sub-delimiters (e.g. "@"/";") that iOS 17+ leaves literal. Assert
        // only the path-allowed characters that are stable across every supported
        // OS version — "/" (path separator) and "," (used to join array path items).
        #expect(APIHelper.escapedPathItem("a/b,c") == "a/b,c")
    }

    @Test("Array value is comma-joined then escaped")
    func escapedPathItem_arrayValue() {
        #expect(APIHelper.escapedPathItem(["a", "b c"]) == "a,b%20c")
    }

    @Test("nil value maps to an empty component")
    func escapedPathItem_nil() {
        #expect(APIHelper.escapedPathItem(nil) == "")
    }

    @Test("Matches the previous two-step mapValueToPathItem + addingPercentEncoding")
    func escapedPathItem_matchesLegacyTwoStep() {
        for value in ["foo bar/baz", "100% done", "messaging:general"] as [Any] {
            let preEscape = "\(APIHelper.mapValueToPathItem(value))"
            let postEscape = preEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            #expect(APIHelper.escapedPathItem(value) == postEscape)
        }

        let array: [String] = ["a", "b c", "d/e"]
        let preEscape = "\(APIHelper.mapValueToPathItem(array))"
        let postEscape = preEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        #expect(APIHelper.escapedPathItem(array) == postEscape)
    }
}
