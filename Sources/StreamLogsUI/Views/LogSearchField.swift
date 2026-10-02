//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, *)
struct LogSearchField: View {
    let placeholder: String
    @Binding var text: String
    let isSearching: Bool
    let currentMatchIndex: Int?
    let matchCount: Int
    let showPreviousMatch: () -> Void
    let showNextMatch: () -> Void

    var body: some View {
        HStack(spacing: LogTokens.Spacing.xs) {
            HStack(spacing: LogTokens.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(LogTokens.Colors.textTertiary)
                    .accessibilityHidden(true)
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit(showNextMatch)
                if !text.isEmpty {
                    Text(matchSummary)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(LogTokens.Colors.textTertiary)
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(LogTokens.Colors.textTertiary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .font(.subheadline)
            .padding(.horizontal, LogTokens.Spacing.sm)
            .padding(.vertical, LogTokens.Spacing.xs)
            .background(LogTokens.Colors.backgroundSurfaceCard, in: Capsule())
            .overlay(Capsule().strokeBorder(LogTokens.Colors.borderDefault))

            if matchCount > 1 {
                iconButton("chevron.up", label: "Previous match", action: showPreviousMatch)
                iconButton("chevron.down", label: "Next match", action: showNextMatch)
            }
        }
    }

    private var matchSummary: String {
        guard !isSearching else { return "…" }
        guard let currentMatchIndex else { return "No matches" }
        return "\(currentMatchIndex + 1) of \(matchCount)"
    }

    private func iconButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(LogTokens.Colors.backgroundSurfaceCard, in: Circle())
                .overlay(Circle().strokeBorder(LogTokens.Colors.borderDefault))
                .foregroundColor(LogTokens.Colors.textPrimary)
        }
        .accessibilityLabel(label)
    }
}

@available(iOS 16.0, *)
struct LogExpandButton: View {
    let isExpanded: Bool
    let expandTitle: String
    let collapseTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(
                isExpanded ? collapseTitle : expandTitle,
                systemImage: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
            )
            .font(.footnote.weight(.semibold))
            .foregroundColor(LogTokens.Colors.accentPrimary)
        }
        .buttonStyle(.borderless)
    }
}
