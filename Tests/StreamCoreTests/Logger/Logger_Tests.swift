//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamCore
import Testing

struct Logger_Tests {
    // MARK: - Concurrent Logger Invalidation Tests

    @Test func concurrentLoggerInvalidation() async throws {
        let iterations = 50
        defer {
            resetLogConfig()
        }
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    // Each thread modifies different LogConfig properties to trigger invalidation
                    switch i % 5 {
                    case 0:
                        LogConfig.identifier = "Thread-\(i)"
                    case 1:
                        LogConfig.level = [.debug, .info, .warning, .error].randomElement()!
                    case 2:
                        LogConfig.showDate.toggle()
                    case 3:
                        LogConfig.showLevel.toggle()
                    case 4:
                        LogConfig.subsystems = [.other, .database, .webSocket, .all].randomElement()!
                    default:
                        break
                    }
                }
            }
        }
        
        // Verify logger is still functional after concurrent invalidation
        let logger = LogConfig.logger
        logger.info("Test message after concurrent invalidation")
    }

    @Test func concurrentLoggerAccessDuringInvalidation() async throws {
        let iterations = 100
        defer {
            resetLogConfig()
        }
        await withTaskGroup(of: Void.self) { group in
            // Half the tasks will invalidate the logger
            for _ in 0..<iterations {
                group.addTask {
                    LogConfig.level = [.debug, .info, .warning, .error].randomElement()!
                }
            }
            
            // Half the tasks will access the logger
            for i in 0..<iterations {
                group.addTask {
                    let logger = LogConfig.logger
                    logger.info("Concurrent access message \(i)")
                }
            }
        }
    }

    @Test func concurrentLoggerInstanceReplacement() async throws {
        let iterations = 50
        defer {
            resetLogConfig()
        }
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    // Create and set a new logger instance
                    let newLogger = Logger(identifier: "TestLogger-\(i)")
                    LogConfig.logger = newLogger
                }
            }
        }
        
        // Verify we can still access the logger
        let logger = LogConfig.logger
        logger.info("Test message after concurrent logger replacement")
    }

    @Test func concurrentMixedOperations() async throws {
        let iterations = 40
        defer {
            resetLogConfig()
        }
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                // Task 1: Modify config properties
                group.addTask {
                    LogConfig.identifier = "Mixed-\(i)"
                    LogConfig.level = [.debug, .info, .warning, .error].randomElement()!
                }
                
                // Task 2: Access logger
                group.addTask {
                    let logger = LogConfig.logger
                    logger.debug("Debug message \(i)")
                    logger.info("Info message \(i)")
                }
                
                // Task 3: Replace logger instance
                group.addTask {
                    let newLogger = Logger(identifier: "MixedLogger-\(i)")
                    LogConfig.logger = newLogger
                }
            }
        }
        
        // Final verification
        let finalLogger = LogConfig.logger
        finalLogger.info("Final test message after mixed operations")
    }

    @Test func loggerThreadSafetyHighContention() async throws {
        let iterations = 200
        defer {
            resetLogConfig()
        }
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    LogConfig.showDate.toggle()
                    LogConfig.showLevel.toggle()
                    LogConfig.level = [.debug, .info, .warning, .error].randomElement()!
                    
                    let logger = LogConfig.logger
                    logger.warning("High contention message \(i)")
                }
            }
        }
    }
    
    // MARK: -
    
    private func resetLogConfig() {
        LogConfig.reset()
    }
}
