//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@MainActor
final class LogListViewModel: ObservableObject {
    @Published private(set) var entries: [LogEntry]
    @Published var searchText = ""
    @Published var selectedLevel: LogEntry.Level?
    @Published var selectedSubsystems: Set<String> = []
    @Published var isRecording: Bool {
        didSet { store.isRecording = isRecording }
    }

    private let store: any LogStore

    init(store: any LogStore) {
        self.store = store
        entries = store.entries
        isRecording = store.isRecording
        store.entriesPublisher
            .throttle(for: .milliseconds(250), scheduler: DispatchQueue.main, latest: true)
            .assign(to: &$entries)
    }

    var filteredEntries: [LogEntry] {
        entries.reversed().filter { entry in
            if let selectedLevel, entry.level != selectedLevel {
                return false
            }
            if !selectedSubsystems.isEmpty, selectedSubsystems.isDisjoint(with: entry.subsystems) {
                return false
            }
            if !searchText.isEmpty {
                return entry.message.localizedCaseInsensitiveContains(searchText)
                    || entry.functionName?.localizedCaseInsensitiveContains(searchText) == true
                    || entry.fileName?.localizedCaseInsensitiveContains(searchText) == true
                    || entry.subsystems.contains { $0.localizedCaseInsensitiveContains(searchText) }
                    || entry.metadata.contains {
                        $0.key.localizedCaseInsensitiveContains(searchText) || $0.value.localizedCaseInsensitiveContains(searchText)
                    }
            }
            return true
        }
    }

    var availableSubsystems: [String] {
        Set(entries.flatMap(\.subsystems)).union(selectedSubsystems).sorted()
    }

    var isFiltering: Bool {
        !searchText.isEmpty || selectedLevel != nil || !selectedSubsystems.isEmpty
    }

    func removeEntry(_ entry: LogEntry) {
        store.removeEntry(id: entry.id)
    }

    func removeAll() {
        store.removeAll()
    }
}
