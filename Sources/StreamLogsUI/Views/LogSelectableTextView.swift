//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct LogSelectableTextView: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: .monospacedSystemFont(ofSize: 13, weight: .regular))
        textView.adjustsFontForContentSizeCategory = true
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.text = text
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }
}
