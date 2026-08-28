//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import SwiftUI
import UIKit
import XCTest

final class SharedImages_Tests: XCTestCase {
    private lazy var subject: SharedImages! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Symbol resolution

    func test_systemSymbol_resolvesUIKitFace() {
        XCTAssertEqual(subject.close.uiImage, UIImage(systemName: "xmark"))
    }

    func test_systemSymbol_swiftUIFaceMatchesSymbol() {
        XCTAssertEqual(subject.close.image, Image(systemName: "xmark"))
    }

    func test_unavailableSymbol_resolvesToEmptyUIKitFace() {
        let image = SharedImage.system("not.a.real.symbol")

        XCTAssertEqual(image.uiImage.size, .zero)
    }

    // MARK: - Overrides

    func test_uiKitFaceOverridden_swiftUIFaceUnchanged() {
        let original = subject.close.image

        subject.close.uiImage = UIImage()

        XCTAssertEqual(subject.close.image, original)
    }

    func test_iconOverridden_readsBackOverride() {
        let replacement = SharedImage.system("trash")

        subject.close = replacement

        XCTAssertEqual(subject.close.uiImage, replacement.uiImage)
    }
}
