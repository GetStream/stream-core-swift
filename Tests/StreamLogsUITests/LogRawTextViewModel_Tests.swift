//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamLogsUI
import Testing

@MainActor
struct LogRawTextViewModel_Tests {
    private let subject = LogRawTextViewModel(searchDebounceNanoseconds: 0)

    @Test func truncatedTextShowsOnlyThePreviewUntilExpanded() {
        subject.load(chunks: ["a", "b", "c"], previewChunkCount: 2)

        #expect(subject.isTruncated)
        #expect(subject.visibleChunkCount == 2)

        subject.isExpanded = true
        #expect(subject.visibleChunkCount == 3)
    }

    @Test func textThatFitsShowsAllChunks() {
        subject.load(chunks: ["a", "b"], previewChunkCount: nil)

        #expect(!subject.isTruncated)
        #expect(subject.visibleChunkCount == 2)
    }

    @Test func searchMatchesEachChunkOnceIgnoringCase() async {
        subject.load(chunks: ["Status Code: 200", "status: ok status", "body"], previewChunkCount: nil)

        subject.searchText = "status"
        await subject.waitForSearch()

        #expect(subject.matchedText == "status")
        #expect(subject.matchIndices == [0, 1])
        #expect(subject.currentChunkIndex == 0)
    }

    @Test func searchExpandsTheTextWhenTheCurrentMatchIsPastThePreview() async {
        subject.load(chunks: ["a", "b", "c"], previewChunkCount: 1)

        subject.searchText = "a"
        await subject.waitForSearch()
        #expect(!subject.isExpanded)

        subject.searchText = "c"
        await subject.waitForSearch()
        #expect(subject.isExpanded)
    }

    @Test func matchNavigationWrapsAround() async {
        subject.load(chunks: ["a", "b", "a", "a"], previewChunkCount: nil)
        subject.searchText = "a"
        await subject.waitForSearch()

        subject.showPreviousMatch()
        #expect(subject.currentChunkIndex == 3)

        subject.showNextMatch()
        #expect(subject.currentChunkIndex == 0)
    }

    @Test func clearingTheSearchClearsTheMatches() async {
        subject.load(chunks: ["a", "b"], previewChunkCount: nil)
        subject.searchText = "a"
        await subject.waitForSearch()

        subject.searchText = ""
        await subject.waitForSearch()

        #expect(subject.matchIndices.isEmpty)
        #expect(subject.currentMatchIndex == nil)
    }

    @Test func loadingCollapsesTheTextAndReappliesTheSearch() async {
        subject.searchText = "b"
        await subject.waitForSearch()
        subject.isExpanded = true

        subject.load(chunks: ["a", "b"], previewChunkCount: 1)
        #expect(!subject.isExpanded)
        await subject.waitForSearch()

        #expect(subject.matchIndices == [1])
        #expect(subject.isExpanded)
    }
}
