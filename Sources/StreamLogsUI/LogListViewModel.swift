//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class LogListViewModel: ObservableObject {
    struct Content: Equatable, Sendable {
        var filter = LogFilter()
        var filteredEntries: [LogEntry] = []
        var availableLevels: [LogEntry.Level] = []
        var availableSubsystems: [String] = []
    }

    @Published private(set) var content = Content()
    @Published private(set) var newEntriesCount = 0
    @Published var searchText = ""
    @Published var selectedLevels: Set<LogEntry.Level> = []
    @Published var selectedSubsystems: Set<String> = []
    @Published var isRecording: Bool {
        didSet { recorder.isRecording = isRecording }
    }

    // While the list is scrolled away from the newest entries, new entries are held back
    // until `showNewEntries()`, so that the visible rows don't move.
    var isFollowingNewEntries = true {
        didSet {
            if isFollowingNewEntries {
                showNewEntries()
            }
        }
    }

    private let recorder: any LogRecorder
    private var heldContent: Content?
    private var cancellable: AnyCancellable?

    init(
        recorder: any LogRecorder,
        filter initialFilter: LogFilter = LogFilter(),
        searchDebounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200)
    ) {
        self.recorder = recorder
        isRecording = recorder.isRecording
        searchText = initialFilter.searchText
        selectedLevels = initialFilter.levels
        selectedSubsystems = initialFilter.subsystems
        content = Self.makeContent(entries: recorder.entries, filter: initialFilter)

        let searchText = $searchText
            .dropFirst()
            .debounce(for: searchDebounceInterval, scheduler: DispatchQueue.main)
            .prepend(self.searchText)
        let filter = Publishers.CombineLatest3(searchText, $selectedLevels, $selectedSubsystems)
            .map { LogFilter(searchText: $0, levels: $1, subsystems: $2) }
            .removeDuplicates()
            .eraseToAnyPublisher()
        cancellable = Self.contentPublisher(entries: recorder.entriesPublisher, filter: filter)
            .sink { [weak self] in self?.receive($0) }
    }

    var filteredEntries: [LogEntry] { content.filteredEntries }

    var availableLevels: [LogEntry.Level] { content.availableLevels }

    var availableSubsystems: [String] { content.availableSubsystems }

    var isFiltering: Bool {
        !searchText.isEmpty || !selectedLevels.isEmpty || !selectedSubsystems.isEmpty
    }

    func removeEntry(_ entry: LogEntry) {
        recorder.removeEntry(id: entry.id)
    }

    func removeAll() {
        recorder.removeAll()
    }

    func showNewEntries() {
        guard let heldContent else { return }
        self.heldContent = nil
        newEntriesCount = 0
        content = heldContent
    }

    func refreshRecordingState() {
        if isRecording != recorder.isRecording {
            isRecording = recorder.isRecording
        }
    }

    private func receive(_ newContent: Content) {
        guard !isFollowingNewEntries, newContent.filter == content.filter else {
            heldContent = nil
            newEntriesCount = 0
            content = newContent
            return
        }
        let displayedIDs = Set(content.filteredEntries.map(\.id))
        let remainingIDs = Set(newContent.filteredEntries.map(\.id))
        let count = newContent.filteredEntries.count { !displayedIDs.contains($0.id) }
        heldContent = count > 0 ? newContent : nil
        newEntriesCount = count

        var visibleContent = newContent
        visibleContent.filteredEntries = content.filteredEntries.filter { remainingIDs.contains($0.id) }
        if visibleContent != content {
            content = visibleContent
        }
    }

    // Built outside of the main actor, so that filtering runs on the processing queue.
    private nonisolated static func contentPublisher(
        entries: AnyPublisher<[LogEntry], Never>,
        filter: AnyPublisher<LogFilter, Never>
    ) -> AnyPublisher<Content, Never> {
        let processingQueue = DispatchQueue(label: "io.getstream.logs-ui.log-list", qos: .userInitiated)
        return entries
            .throttle(for: .milliseconds(100), scheduler: processingQueue, latest: true)
            .combineLatest(filter.receive(on: processingQueue))
            .map { entries, filter in makeContent(entries: entries, filter: filter) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    nonisolated static func makeContent(entries: [LogEntry], filter: LogFilter) -> Content {
        var levels = filter.levels
        var subsystems = filter.subsystems
        var filteredEntries: [LogEntry] = []
        for entry in entries.reversed() {
            levels.insert(entry.level)
            subsystems.formUnion(entry.subsystems)
            if filter.matches(entry) {
                filteredEntries.append(entry)
            }
        }
        return Content(
            filter: filter,
            filteredEntries: filteredEntries,
            availableLevels: levels.sorted(),
            availableSubsystems: subsystems.sorted()
        )
    }
}

private extension LogFilter {
    func matches(_ entry: LogEntry) -> Bool {
        if !levels.isEmpty, !levels.contains(entry.level) {
            return false
        }
        if !subsystems.isEmpty, subsystems.isDisjoint(with: entry.subsystems) {
            return false
        }
        guard !searchText.isEmpty else { return true }
        return contains(entry.message)
            || entry.functionName.map(contains) == true
            || entry.fileName.map(contains) == true
            || entry.subsystems.contains(where: contains)
            || entry.metadata.contains { contains($0.key.rawValue) || contains($0.value) }
    }

    private func contains(_ text: String) -> Bool {
        text.range(of: searchText, options: .caseInsensitive) != nil
    }
}
