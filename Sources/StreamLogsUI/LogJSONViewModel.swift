//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class LogJSONViewModel: ObservableObject {
    @Published private(set) var tree = LogJSONTree()
    @Published private(set) var visibleIDs: [Int] = []
    @Published private(set) var expandedIDs: Set<Int> = []
    // The node that was last expanded or collapsed.
    @Published private(set) var focusedID: Int?
    @Published var searchText = "" {
        didSet {
            if searchText != oldValue {
                scheduleSearch()
            }
        }
    }

    // The search text of the current matches, which lags behind `searchText` while searching.
    @Published private(set) var matchedText = ""
    @Published private(set) var matchIDs: [Int] = []
    @Published private(set) var currentMatchIndex: Int?

    private let searchDebounceNanoseconds: UInt64
    private var searchTask: Task<Void, Never>?

    init(searchDebounceNanoseconds: UInt64 = 200_000_000) {
        self.searchDebounceNanoseconds = searchDebounceNanoseconds
    }

    var currentMatchID: Int? {
        currentMatchIndex.map { matchIDs[$0] }
    }

    var isFullyExpanded: Bool {
        !tree.containerIDs.isEmpty && expandedIDs.isSuperset(of: tree.containerIDs)
    }

    func load(_ tree: LogJSONTree) {
        self.tree = tree
        expandedIDs = []
        focusedID = nil
        matchIDs = []
        currentMatchIndex = nil
        matchedText = ""
        updateVisibleIDs()
        if !searchText.isEmpty {
            scheduleSearch()
        }
    }

    func toggle(_ id: Int) {
        if expandedIDs.contains(id) {
            expandedIDs.remove(id)
        } else {
            expandedIDs.insert(id)
        }
        focusedID = id
        updateVisibleIDs()
    }

    func expandAll() {
        expandedIDs = tree.containerIDs
        updateVisibleIDs()
    }

    func collapseAll() {
        expandedIDs = []
        updateVisibleIDs()
    }

    func showNextMatch() {
        guard let currentMatchIndex else { return }
        self.currentMatchIndex = (currentMatchIndex + 1) % matchIDs.count
    }

    func showPreviousMatch() {
        guard let currentMatchIndex else { return }
        self.currentMatchIndex = (currentMatchIndex - 1 + matchIDs.count) % matchIDs.count
    }

    // Waits for the search to finish, so that tests can check the matches.
    func waitForSearch() async {
        await searchTask?.value
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let query = searchText
        let tree = tree
        let delay = searchDebounceNanoseconds
        searchTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            let matches = await Task.detached(priority: .userInitiated) { tree.matches(for: query) }.value
            guard !Task.isCancelled else { return }
            self?.applyMatches(matches, for: query)
        }
    }

    private func applyMatches(_ matches: [Int], for query: String) {
        matchedText = query
        matchIDs = matches
        currentMatchIndex = matches.isEmpty ? nil : 0
        for id in matches {
            expandedIDs.formUnion(tree.ancestors(of: id))
        }
        updateVisibleIDs()
    }

    private func updateVisibleIDs() {
        visibleIDs = tree.visibleIDs(expanded: expandedIDs)
    }
}
