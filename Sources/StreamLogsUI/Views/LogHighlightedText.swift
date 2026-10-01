//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogHighlightedText: View {
    let text: String
    let searchText: String
    // Characters kept around the match, so it stays visible when the text is truncated.
    var contextLength = 100

    var body: some View {
        Text(attributedText)
    }

    private var attributedText: AttributedString {
        guard !searchText.isEmpty, let match = text.range(of: searchText, options: .caseInsensitive) else {
            return AttributedString(text)
        }
        let end = text.index(match.upperBound, offsetBy: contextLength, limitedBy: text.endIndex) ?? text.endIndex
        let unusedContext = contextLength - text.distance(from: match.upperBound, to: end)
        let start = text.index(match.lowerBound, offsetBy: -unusedContext, limitedBy: text.startIndex) ?? text.startIndex

        var highlighted = AttributedString(String(text[match]))
        highlighted.backgroundColor = Color.yellow.opacity(0.3)

        var result = AttributedString(start > text.startIndex ? "…" : "")
        result += AttributedString(String(text[start..<match.lowerBound]))
        result += highlighted
        result += AttributedString(String(text[match.upperBound..<end]))
        if end < text.endIndex {
            result += AttributedString("…")
        }
        return result
    }
}
