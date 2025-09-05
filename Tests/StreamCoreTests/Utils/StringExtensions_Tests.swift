//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamCore
import XCTest

final class StringExtensions_Tests: XCTestCase {
    func test_Levenshtein() throws {
        XCTAssertEqual("".levenshtein(""), "".levenshtein(""))
        XCTAssertEqual("".levenshtein(""), 0)
        XCTAssertEqual("a".levenshtein(""), 1)
        XCTAssertEqual("".levenshtein("a"), 1)
        XCTAssertEqual("tommaso".levenshtein("ToMmAsO"), 4)
    }
}
