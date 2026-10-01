//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class LogListViewModel: ObservableObject {
    struct Filter: Equatable, Sendable {
        var searchText = ""
        var minimumLevel: LogEntry.Level?
        var subsystems: Set<String> = []
    }

    struct Content: Sendable {
        var filteredEntries: [LogEntry] = []
        var availableLevels: [LogEntry.Level] = []
        var availableSubsystems: [String] = []
    }

    @Published private(set) var content = Content()
    @Published var searchText = ""
    @Published var minimumLevel: LogEntry.Level?
    @Published var selectedSubsystems: Set<String> = []
    @Published var isRecording: Bool {
        didSet { store.isRecording = isRecording }
    }

    private let store: any LogStore

    init(store: any LogStore, searchDebounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200)) {
        self.store = store
        isRecording = store.isRecording
        content = Self.makeContent(entries: store.entries, filter: Filter())

        let searchText = $searchText
            .dropFirst()
            .debounce(for: searchDebounceInterval, scheduler: DispatchQueue.main)
            .prepend(self.searchText)
        let filter = Publishers.CombineLatest3(searchText, $minimumLevel, $selectedSubsystems)
            .map { Filter(searchText: $0, minimumLevel: $1, subsystems: $2) }
            .removeDuplicates()
            .eraseToAnyPublisher()
        Self.contentPublisher(entries: store.entriesPublisher, filter: filter)
            .assign(to: &$content)
    }

    var filteredEntries: [LogEntry] { content.filteredEntries }

    var availableLevels: [LogEntry.Level] { content.availableLevels }

    var availableSubsystems: [String] { content.availableSubsystems }

    var isFiltering: Bool {
        !searchText.isEmpty || minimumLevel != nil || !selectedSubsystems.isEmpty
    }

    func removeEntry(_ entry: LogEntry) {
        store.removeEntry(id: entry.id)
    }

    func removeAll() {
        store.removeAll()
    }

    // Built outside of the main actor, so that filtering runs on the processing queue.
    private nonisolated static func contentPublisher(
        entries: AnyPublisher<[LogEntry], Never>,
        filter: AnyPublisher<Filter, Never>
    ) -> AnyPublisher<Content, Never> {
        let processingQueue = DispatchQueue(label: "io.getstream.logs-ui.log-list", qos: .userInitiated)
        return entries
            .throttle(for: .milliseconds(100), scheduler: processingQueue, latest: true)
            .combineLatest(filter.receive(on: processingQueue))
            .map { entries, filter in makeContent(entries: entries, filter: filter) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    nonisolated static func makeContent(entries: [LogEntry], filter: Filter) -> Content {
        var levels = Set(filter.minimumLevel.map { [$0] } ?? [])
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
            filteredEntries: filteredEntries,
            availableLevels: levels.sorted(),
            availableSubsystems: subsystems.sorted()
        )
    }
}

private extension LogListViewModel.Filter {
    func matches(_ entry: LogEntry) -> Bool {
        if let minimumLevel, entry.level < minimumLevel {
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
            || entry.metadata.contains { contains($0.key) || contains($0.value) }
    }

    private func contains(_ text: String) -> Bool {
        text.range(of: searchText, options: .caseInsensitive) != nil
    }
}
