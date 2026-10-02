//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamLogsUI
import Testing

struct LogJSONTree_Tests {
    private let subject = LogJSONTree(documents: [
        ("Request Body", #"{"limit":10}"#),
        ("Response Body", #"{"channels":[{"id":"general","muted":false}],"next":null,"duration":"1.5ms"}"#)
    ])

    @Test func documentsAreRootsWithSortedKeys() {
        #expect(subject.roots.count == 2)
        #expect(subject.nodes[subject.roots[0]].key == .title("Request Body"))
        #expect(subject.nodes[subject.roots[1]].value == .object(count: 3))
        #expect(subject.nodes[subject.roots[1]].children.map { subject.nodes[$0].key } == [.name("channels"), .name("duration"), .name("next")])
    }

    @Test func valuesAreTyped() {
        let values = subject.nodes.map(\.value)

        #expect(values.contains(.number("10")))
        #expect(values.contains(.array(count: 1)))
        #expect(values.contains(.string("general")))
        #expect(values.contains(.bool(false)))
        #expect(values.contains(.null))
    }

    @Test func invalidDocumentsAreSkipped() {
        let tree = LogJSONTree(documents: [("Request Body", "not json"), ("Response Body", "[]")])

        #expect(tree.roots.count == 1)
        #expect(tree.nodes[tree.roots[0]].key == .title("Response Body"))
        #expect(LogJSONTree(documents: [("Body", "")]).isEmpty)
    }

    @Test func onlyRootsAreVisibleWhenCollapsed() {
        #expect(subject.visibleIDs(expanded: []) == subject.roots)
    }

    @Test func expandedNodesShowTheirChildrenInOrder() {
        let response = subject.roots[1]

        let visible = subject.visibleIDs(expanded: [response])

        #expect(visible == [subject.roots[0], response] + subject.nodes[response].children)
    }

    @Test func allNodesAreVisibleWhenAllContainersAreExpanded() {
        #expect(subject.visibleIDs(expanded: subject.containerIDs) == subject.nodes.map(\.id))
    }

    @Test func searchMatchesKeysAndScalarValuesCaseInsensitively() {
        let matches = subject.matches(for: "GENERAL").map { subject.nodes[$0].value }

        #expect(matches == [.string("general")])
        #expect(subject.matches(for: "next").map { subject.nodes[$0].key } == [.name("next")])
    }

    @Test func searchDoesNotMatchRootTitlesOrContainerSummaries() {
        #expect(subject.matches(for: "Body").isEmpty)
        #expect(subject.matches(for: "items").isEmpty)
        #expect(subject.matches(for: "").isEmpty)
    }

    @Test func ancestorsAreListedFromTheParent() throws {
        let id = try #require(subject.matches(for: "general").first)

        let ancestors = subject.ancestors(of: id)

        #expect(ancestors.last == subject.roots[1])
        #expect(ancestors.map { subject.nodes[$0].depth } == [2, 1, 0])
    }

    @Test func jsonTextIsPrettyPrintedForContainersAndRawForScalars() throws {
        let general = try #require(subject.matches(for: "general").first)

        #expect(subject.jsonText(for: subject.roots[0]) == "{\n  \"limit\" : 10\n}")
        #expect(subject.jsonText(for: general) == "general")
        #expect(subject.jsonText(for: subject.roots[1]).contains("\"next\" : null"))
        #expect(subject.jsonText(for: subject.roots[1]).contains("\"muted\" : false"))
    }
}
