//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct LogJSONNodeRow: View {
    let node: LogJSONTree.Node
    let isExpanded: Bool
    let searchText: String
    let isCurrentMatch: Bool
    let isFocused: Bool
    let toggle: () -> Void
    let jsonText: () -> String
    @Environment(\.logViewerAppearance) private var appearance

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: LogTokens.Spacing.xxs) {
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundColor(LogTokens.Colors.textTertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .frame(width: 12)
                .opacity(node.value.isContainer ? 1 : 0)
                .accessibilityHidden(true)

            text
                .font(.system(.footnote, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, CGFloat(node.depth) * LogTokens.Spacing.md)
        .padding(.horizontal, LogTokens.Spacing.xs)
        .padding(.vertical, LogTokens.Spacing.xxs)
        .background(background, in: RoundedRectangle(cornerRadius: LogTokens.Radius.sm))
        .contentShape(Rectangle())
        .onTapGesture {
            guard node.value.isContainer else { return }
            toggle()
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = jsonText()
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
            if case let .name(name) = node.key {
                Button {
                    UIPasteboard.general.string = name
                } label: {
                    Label("Copy Key", systemImage: "key")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(node.value.isContainer ? .isButton : [])
        .accessibilityValue(node.value.isContainer ? (isExpanded ? "Expanded" : "Collapsed") : "")
    }

    private var background: Color {
        if isCurrentMatch {
            return LogTokens.Colors.accentPrimary.opacity(0.12)
        }
        return isFocused ? LogTokens.Colors.accentNeutral.opacity(0.16) : .clear
    }

    private var text: Text {
        let value = valueText
        switch node.key {
        case let .title(title):
            return Text(title).fontWeight(.semibold).foregroundColor(LogTokens.Colors.textPrimary) + Text("  ") + value
        case let .name(name):
            return (Text("\"") + highlighted(name) + Text("\"")).foregroundColor(LogTokens.Colors.jsonKey)
                + Text(": ").foregroundColor(LogTokens.Colors.textTertiary)
                + value
        case .index:
            return Text(node.key.text).foregroundColor(LogTokens.Colors.textTertiary)
                + Text(": ").foregroundColor(LogTokens.Colors.textTertiary)
                + value
        }
    }

    private var valueText: Text {
        switch node.value {
        case .object, .array:
            return Text(node.value.text).foregroundColor(LogTokens.Colors.textTertiary)
        case let .string(string):
            return (Text("\"") + highlighted(string) + Text("\"")).foregroundColor(LogTokens.Colors.jsonString)
        case .number:
            return highlighted(node.value.text).foregroundColor(LogTokens.Colors.jsonNumber)
        case .bool, .null:
            return highlighted(node.value.text).foregroundColor(LogTokens.Colors.jsonLiteral)
        }
    }

    private func highlighted(_ text: String) -> Text {
        Text(LogHighlightedText.attributedString(text, highlighting: searchText, color: appearance.highlightColor))
    }
}
