//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
@testable import StreamLogsUI
import Testing

struct LogFlowLayout_Tests {
    @Test func subviewsThatFitStayOnTheSameRow() {
        let frames = LogFlowLayout.frames(for: [CGSize(width: 40, height: 20), CGSize(width: 50, height: 20)], width: 100, spacing: 4)

        #expect(frames == [CGRect(x: 0, y: 0, width: 40, height: 20), CGRect(x: 44, y: 0, width: 50, height: 20)])
    }

    @Test func subviewsThatDoNotFitStartANewRowBelowTheTallestSubview() {
        let sizes = [CGSize(width: 60, height: 20), CGSize(width: 30, height: 24), CGSize(width: 30, height: 20)]

        let frames = LogFlowLayout.frames(for: sizes, width: 100, spacing: 4)

        #expect(frames == [
            CGRect(x: 0, y: 0, width: 60, height: 20),
            CGRect(x: 64, y: 0, width: 30, height: 24),
            CGRect(x: 0, y: 28, width: 30, height: 20)
        ])
    }

    @Test func subviewWiderThanTheRowIsPlacedAlone() {
        let frames = LogFlowLayout.frames(for: [CGSize(width: 150, height: 20), CGSize(width: 10, height: 20)], width: 100, spacing: 4)

        #expect(frames == [CGRect(x: 0, y: 0, width: 150, height: 20), CGRect(x: 0, y: 24, width: 10, height: 20)])
    }
}
