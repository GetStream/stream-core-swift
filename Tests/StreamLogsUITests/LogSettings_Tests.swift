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
    }

    override func tearDown() async throws {
        subject = nil
        try await super.tearDown()
    }

    func test_init_usesDefaults() {
        XCTAssertTrue(subject.isEnabled)
        XCTAssertEqual(subject.level, .warning)
        XCTAssertTrue(subject.disabledSubsystems.isEmpty)
    }

    func test_setDefaults_overridesCurrentValues() {
        subject.isEnabled = false
        subject.level = .debug

        subject.setDefaults(isEnabled: true, level: .info, disabledSubsystems: ["database"])

        XCTAssertTrue(subject.isEnabled)
        XCTAssertEqual(subject.level, .info)
        XCTAssertEqual(subject.disabledSubsystems, ["database"])
    }

    func test_reset_restoresDefaults() {
        subject.setDefaults(level: .info)
        subject.isEnabled = false
        subject.level = .debug
        subject.setSubsystem("database", isEnabled: false)

        subject.reset()

        XCTAssertTrue(subject.isEnabled)
        XCTAssertEqual(subject.level, .info)
        XCTAssertTrue(subject.disabledSubsystems.isEmpty)
    }

    func test_reset_notifiesHandlersOnce() {
        var callCount = 0
        subject.apply { _ in callCount += 1 }
        subject.isEnabled = false
        subject.level = .debug
        callCount = 0

        subject.reset()

        XCTAssertEqual(callCount, 1)
    }

    func test_enabledSubsystems_excludesDisabledSubsystems() {
        subject.availableSubsystems = ["database", "httpRequests", "webSocket"]

        subject.setSubsystem("httpRequests", isEnabled: false)

        XCTAssertEqual(subject.enabledSubsystems, ["database", "webSocket"])
    }

    func test_apply_callsHandlerImmediatelyAndOnEveryChange() {
        var levels: [LogEntry.Level] = []

        subject.apply { levels.append($0.level) }
        subject.level = .error

        XCTAssertEqual(levels, [.warning, .error])
    }
}
