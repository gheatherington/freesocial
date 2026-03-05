import XCTest
@testable import ScreenTimeEngine

// MARK: - ActivitySchedulerTests
// Validates per-platform threshold mapping, input validation, idempotency,
// and token-selection guard for ActivityScheduler.

final class ActivitySchedulerTests: XCTestCase {

    // MARK: - Threshold mapping

    /// Scheduler must produce distinct DeviceActivityEvent.Name values for Instagram and TikTok.
    /// Asserts explicit per-platform constant mapping defined in the ScreenTimeEngine namespace.
    func testStartMonitoring_MapsInstagramAndTikTokThresholdsToEvents() throws {
        let scheduler = ActivityScheduler()
        let config = try scheduler.buildMonitoringConfiguration(
            platformLimits: [.instagram: 30, .tiktok: 45]
        )
        XCTAssertEqual(config.events[ScreenTimeEngine.EventName.instagramDailyLimit]?.threshold.minute, 30)
        XCTAssertEqual(config.events[ScreenTimeEngine.EventName.tiktokDailyLimit]?.threshold.minute, 45)
    }

    /// Instagram and TikTok thresholds must map to different event name keys.
    func testStartMonitoring_InstagramAndTikTokMappedToDistinctEventNames() throws {
        let scheduler = ActivityScheduler()
        let config = try scheduler.buildMonitoringConfiguration(
            platformLimits: [.instagram: 20, .tiktok: 20]
        )
        XCTAssertNotEqual(
            ScreenTimeEngine.EventName.instagramDailyLimit,
            ScreenTimeEngine.EventName.tiktokDailyLimit
        )
        XCTAssertEqual(config.events.count, 2,
            "Expect exactly two events: one per platform")
    }

    // MARK: - Input validation

    /// Zero daily limit must be rejected with an error.
    func testStartMonitoring_RejectsZeroOrNegativePlatformLimits() throws {
        let scheduler = ActivityScheduler()
        XCTAssertThrowsError(
            try scheduler.buildMonitoringConfiguration(platformLimits: [.instagram: 0, .tiktok: 30]),
            "Zero instagram minutes should throw"
        ) { error in
            guard let sched = error as? ActivitySchedulerError else {
                XCTFail("Expected ActivitySchedulerError, got \(error)"); return
            }
            XCTAssertEqual(sched, .invalidDailyLimit(platform: .instagram, minutes: 0))
        }
    }

    /// Negative daily limit must be rejected.
    func testStartMonitoring_RejectsNegativePlatformLimit() throws {
        let scheduler = ActivityScheduler()
        XCTAssertThrowsError(
            try scheduler.buildMonitoringConfiguration(platformLimits: [.instagram: 30, .tiktok: -5]),
            "Negative tiktok minutes should throw"
        ) { error in
            guard let sched = error as? ActivitySchedulerError else {
                XCTFail("Expected ActivitySchedulerError, got \(error)"); return
            }
            XCTAssertEqual(sched, .invalidDailyLimit(platform: .tiktok, minutes: -5))
        }
    }

    /// Missing a required platform entry must be rejected.
    func testStartMonitoring_RejectsMissingPlatformEntry() throws {
        let scheduler = ActivityScheduler()
        // Providing only instagram, no tiktok
        XCTAssertThrowsError(
            try scheduler.buildMonitoringConfiguration(platformLimits: [.instagram: 30]),
            "Missing tiktok entry should throw"
        ) { error in
            guard let sched = error as? ActivitySchedulerError else {
                XCTFail("Expected ActivitySchedulerError, got \(error)"); return
            }
            XCTAssertEqual(sched, .missingPlatformLimit(platform: .tiktok))
        }
    }

    // MARK: - Schedule properties

    /// Daily schedule must be repeating with midnight-to-midnight interval.
    func testStartMonitoring_BuildsDailyRepeatingSchedule() throws {
        let scheduler = ActivityScheduler()
        let config = try scheduler.buildMonitoringConfiguration(
            platformLimits: [.instagram: 60, .tiktok: 60]
        )
        XCTAssertTrue(config.schedule.repeats, "Daily schedule must repeat")
        XCTAssertEqual(config.schedule.intervalStart.hour, 0)
        XCTAssertEqual(config.schedule.intervalStart.minute, 0)
        XCTAssertEqual(config.schedule.intervalEnd.hour, 23)
        XCTAssertEqual(config.schedule.intervalEnd.minute, 59)
    }

    // MARK: - Token selection guard

    /// Scheduler startMonitoring must return .noTokensSelected when no selection persisted.
    func testStartMonitoring_ReturnsNoTokensSelectedWhenStoreEmpty() async throws {
        let testSuite = UUID().uuidString
        let scheduler = ActivityScheduler(suiteName: testSuite)
        let result = await scheduler.startMonitoring(platformLimits: [.instagram: 30, .tiktok: 45])
        XCTAssertEqual(result, .noTokensSelected)
    }

    // MARK: - Idempotency

    /// Calling startMonitoring twice must not throw or crash.
    func testStartMonitoring_IsIdempotent() async throws {
        // Idempotency is structural — stop-then-start must not throw
        let testSuite = UUID().uuidString
        let scheduler = ActivityScheduler(suiteName: testSuite)
        // Both calls return noTokensSelected (no real tokens in test environment)
        let r1 = await scheduler.startMonitoring(platformLimits: [.instagram: 30, .tiktok: 45])
        let r2 = await scheduler.startMonitoring(platformLimits: [.instagram: 30, .tiktok: 45])
        XCTAssertEqual(r1, .noTokensSelected)
        XCTAssertEqual(r2, .noTokensSelected,
            "Second call must succeed (idempotent restart, not a crash or error)")
    }
}
