//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamLogsUI
import XCTest

@MainActor
final class LogSettings_Tests: XCTestCase {
    private var subject: LogSettings!

    override func setUp() async throws {
        try await super.setUp()
        subject = LogSettings()
        subject.availableSubsystems = ["database", "httpRequests", "webSocket"]
        subject.setDefaults([
            LogDestinationSettings(id: "console", name: "Console", level: .error),
            LogDestinationSettings(id: "logViewer", name: "Log Viewer", level: .debug)
        ])
    }

    override func tearDown() async throws {
        subject = nil
        try await super.tearDown()
    }

    func test_init_hasNoDestinations() {
        XCTAssertTrue(LogSettings().destinations.isEmpty)
    }

    func test_subscript_returnsDestinationWithIdentifier() {
        XCTAssertEqual(subject["logViewer"]?.level, .debug)
        XCTAssertNil(subject["unknown"])
    }

    func test_enabledDestinations_excludesDisabledDestinations() {
        subject.destinations[0].isEnabled = false

        XCTAssertEqual(subject.enabledDestinations.map(\.id), ["logViewer"])
    }

    func test_enabledSubsystems_excludesDisabledSubsystems() {
        subject.destinations[0].disabledSubsystems = ["httpRequests"]

        XCTAssertEqual(subject.enabledSubsystems(for: subject.destinations[0]), ["database", "webSocket"])
        XCTAssertEqual(subject.enabledSubsystems(for: subject.destinations[1]), ["database", "httpRequests", "webSocket"])
    }

    func test_setDefaults_overridesCurrentValues() {
        subject.destinations[0].level = .debug

        subject.setDefaults([LogDestinationSettings(id: "console", name: "Console", level: .info)])

        XCTAssertEqual(subject.destinations.map(\.id), ["console"])
        XCTAssertEqual(subject.destinations[0].level, .info)
    }

    func test_reset_restoresDefaults() {
        subject.destinations[0].isEnabled = false
        subject.destinations[1].level = .error
        subject.destinations[1].disabledSubsystems = ["database"]

        subject.reset()

        XCTAssertEqual(subject.destinations.map(\.isEnabled), [true, true])
        XCTAssertEqual(subject.destinations.map(\.level), [.error, .debug])
        XCTAssertTrue(subject.destinations[1].disabledSubsystems.isEmpty)
    }

    func test_reset_notifiesHandlersOnce() {
        var callCount = 0
        subject.apply { _ in callCount += 1 }
        subject.destinations[0].level = .debug
        callCount = 0

        subject.reset()

        XCTAssertEqual(callCount, 1)
    }

    func test_apply_callsHandlerImmediatelyAndOnEveryChange() {
        var levels: [LogEntry.Level] = []

        subject.apply { levels.append($0.destinations[0].level) }
        subject.destinations[0].level = .warning

        XCTAssertEqual(levels, [.error, .warning])
    }

    func test_apply_callsHandlerWhenSubsystemsChange() {
        var callCount = 0
        subject.apply { _ in callCount += 1 }

        subject.availableSubsystems = ["database"]

        XCTAssertEqual(callCount, 2)
    }
}
