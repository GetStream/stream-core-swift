//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

// Searches the chunks of a raw log, matching each chunk at most once, and expands the log
// when the current match is past its preview.
@MainActor
final class LogRawTextViewModel: ObservableObject {
    @Published private(set) var chunks: [String] = []
    @Published private(set) var previewChunkCount: Int?
    @Published var isExpanded = false
    @Published var searchText = "" {
        didSet {
            if searchText != oldValue {
                scheduleSearch()
            }
        }
    }

    // The search text of the current matches, which lags behind `searchText` while searching.
    @Published private(set) var matchedText = ""
    @Published private(set) var matchIndices: [Int] = []
    @Published private(set) var currentMatchIndex: Int? {
        didSet { revealCurrentMatch() }
    }

    private let searchDebounceNanoseconds: UInt64
    private var searchTask: Task<Void, Never>?

    init(searchDebounceNanoseconds: UInt64 = 200_000_000) {
        self.searchDebounceNanoseconds = searchDebounceNanoseconds
    }

    var isTruncated: Bool {
        previewChunkCount != nil
    }

    var visibleChunkCount: Int {
        guard !isExpanded, let previewChunkCount else { return chunks.count }
        return min(previewChunkCount, chunks.count)
    }

    var currentChunkIndex: Int? {
        currentMatchIndex.map { matchIndices[$0] }
    }

    func load(chunks: [String], previewChunkCount: Int?) {
        self.chunks = chunks
        self.previewChunkCount = previewChunkCount
        isExpanded = false
        matchedText = ""
        matchIndices = []
        currentMatchIndex = nil
        if !searchText.isEmpty {
            scheduleSearch()
        }
    }

    func showNextMatch() {
        guard let currentMatchIndex else { return }
        self.currentMatchIndex = (currentMatchIndex + 1) % matchIndices.count
    }

    func showPreviousMatch() {
        guard let currentMatchIndex else { return }
        self.currentMatchIndex = (currentMatchIndex - 1 + matchIndices.count) % matchIndices.count
    }

    // Waits for the search to finish, so that tests can check the matches.
    func waitForSearch() async {
        await searchTask?.value
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let query = searchText
        let chunks = chunks
        let delay = query.isEmpty ? 0 : searchDebounceNanoseconds
        searchTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            let matches = await Task.detached(priority: .userInitiated) {
                query.isEmpty ? [] : chunks.indices.filter { chunks[$0].range(of: query, options: .caseInsensitive) != nil }
            }.value
            guard !Task.isCancelled else { return }
            self?.applyMatches(matches, for: query)
        }
    }

    private func applyMatches(_ matches: [Int], for query: String) {
        matchedText = query
        matchIndices = matches
        currentMatchIndex = matches.isEmpty ? nil : 0
    }

    private func revealCurrentMatch() {
        if let currentChunkIndex, currentChunkIndex >= visibleChunkCount {
            isExpanded = true
        }
    }
}
