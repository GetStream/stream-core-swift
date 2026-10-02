//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamLogsUI
import Testing

@MainActor
struct LogJSONViewModel_Tests {
    private let tree = LogJSONTree(documents: [
        ("Response Body", #"{"channels":[{"id":"general"},{"id":"random"}],"user":{"id":"luke"}}"#)
    ])
    private let subject = LogJSONViewModel(searchDebounceNanoseconds: 0)

    @Test func loadingCollapsesAllNodes() {
        subject.load(tree)

        #expect(subject.visibleIDs == tree.roots)
        #expect(subject.expandedIDs.isEmpty)
    }

    @Test func togglingExpandsAndCollapsesANode() {
        subject.load(tree)
        let root = tree.roots[0]

        subject.toggle(root)
        #expect(subject.visibleIDs == [root] + tree.nodes[root].children)

        subject.toggle(root)
        #expect(subject.visibleIDs == [root])
    }

    @Test func togglingFocusesTheNodeUntilANewTreeIsLoaded() {
        subject.load(tree)
        let root = tree.roots[0]

        subject.toggle(root)
        #expect(subject.focusedID == root)

        subject.load(tree)
        #expect(subject.focusedID == nil)
    }

    @Test func expandAllAndCollapseAll() {
        subject.load(tree)

        subject.expandAll()
        #expect(subject.visibleIDs == tree.nodes.map(\.id))

        subject.collapseAll()
        #expect(subject.visibleIDs == tree.roots)
    }

    @Test func isFullyExpandedOnlyWhenEveryContainerIsExpanded() {
        subject.load(tree)
        #expect(!subject.isFullyExpanded)

        subject.toggle(tree.roots[0])
        #expect(!subject.isFullyExpanded)

        subject.expandAll()
        #expect(subject.isFullyExpanded)
    }

    @Test func searchExpandsTheAncestorsOfMatchesAndSelectsTheFirstMatch() async {
        subject.load(tree)

        subject.searchText = "id"
        await subject.waitForSearch()

        #expect(subject.matchedText == "id")
        #expect(subject.matchIDs.count == 3)
        #expect(subject.currentMatchIndex == 0)
        #expect(subject.matchIDs.allSatisfy { subject.visibleIDs.contains($0) })
    }

    @Test func matchNavigationWrapsAround() async {
        subject.load(tree)
        subject.searchText = "id"
        await subject.waitForSearch()

        subject.showPreviousMatch()
        #expect(subject.currentMatchID == subject.matchIDs[2])

        subject.showNextMatch()
        #expect(subject.currentMatchID == subject.matchIDs[0])
    }

    @Test func searchWithoutMatchesHasNoCurrentMatch() async {
        subject.load(tree)

        subject.searchText = "leia"
        await subject.waitForSearch()

        #expect(subject.matchIDs.isEmpty)
        #expect(subject.currentMatchID == nil)
        #expect(subject.visibleIDs == tree.roots)
    }

    @Test func loadingAnotherTreeKeepsTheSearch() async {
        subject.searchText = "luke"
        await subject.waitForSearch()

        subject.load(tree)
        await subject.waitForSearch()

        #expect(subject.matchIDs.count == 1)
    }
}
