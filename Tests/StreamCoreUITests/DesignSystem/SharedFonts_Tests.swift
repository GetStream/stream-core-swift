//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import SwiftUI
import UIKit
import XCTest

final class SharedFonts_Tests: XCTestCase {
    private lazy var subject: SharedFonts! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Faces

    func test_uiKitFaceOverridden_swiftUIFaceUnchanged() {
        let original = subject.swiftUI.body

        subject.uiKit.body = .systemFont(ofSize: 99)

        XCTAssertEqual(subject.swiftUI.body, original)
    }

    func test_swiftUIFaceOverridden_uiKitFaceUnchanged() {
        let original = subject.uiKit.body

        subject.swiftUI.body = .system(size: 99)

        XCTAssertEqual(subject.uiKit.body, original)
    }

    func test_uiKitFaceOverridden_readsBackOverride() {
        let font = UIFont.systemFont(ofSize: 99)

        subject.uiKit.body = font

        XCTAssertEqual(subject.uiKit.body, font)
    }
}
