//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogHighlightedText: View {
    let text: String
    let searchText: String
    var contextLength = 100
    @Environment(\.logViewerAppearance) private var appearance

    var body: some View {
        Text(Self.attributedString(text, highlighting: searchText, color: appearance.highlightColor, contextLength: contextLength))
    }

    // Long texts are shortened around the first match, or to their start when nothing matches,
    // as laying out very long texts is slow.
    static func attributedString(
        _ text: String,
        highlighting searchText: String,
        color: Color,
        contextLength: Int = 100,
        maxLength: Int = 1000
    ) -> AttributedString {
        guard !searchText.isEmpty, let match = text.range(of: searchText, options: .caseInsensitive) else {
            guard let end = text.index(text.startIndex, offsetBy: maxLength, limitedBy: text.endIndex), end < text.endIndex else {
                return AttributedString(text)
            }
            return AttributedString(text[..<end] + "…")
        }
        let end = text.index(match.upperBound, offsetBy: contextLength, limitedBy: text.endIndex) ?? text.endIndex
        let unusedContext = contextLength - text.distance(from: match.upperBound, to: end)
        let start = text.index(match.lowerBound, offsetBy: -unusedContext, limitedBy: text.startIndex) ?? text.startIndex

        var highlighted = AttributedString(String(text[match]))
        highlighted.backgroundColor = color

        var result = AttributedString(start > text.startIndex ? "…" : "")
        result += AttributedString(String(text[start..<match.lowerBound]))
        result += highlighted
        result += AttributedString(String(text[match.upperBound..<end]))
        if end < text.endIndex {
            result += AttributedString("…")
        }
        return result
    }

    static func attributedString(_ text: String, highlightingAll searchText: String, color: Color) -> AttributedString {
        guard !searchText.isEmpty else { return AttributedString(text) }
        var result = AttributedString()
        var start = text.startIndex
        while let match = text.range(of: searchText, options: .caseInsensitive, range: start..<text.endIndex) {
            result += AttributedString(String(text[start..<match.lowerBound]))
            var highlighted = AttributedString(String(text[match]))
            highlighted.backgroundColor = color
            result += highlighted
            start = match.upperBound
        }
        result += AttributedString(String(text[start...]))
        return result
    }
}
