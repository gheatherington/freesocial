import XCTest
@testable import ScreenTimeEngine

// ENFC-01 UAT: Native app restriction configured via token selection and enforced.
//
// This test class validates the host-testable portions of the full ENFC-01 enforcement
// chain. FamilyControls runtime APIs (authorization sheet, real ApplicationToken sets,
// live DeviceActivityCenter scheduling) require a real device with FamilyControls
// entitlement; those paths are documented in 04-VERIFICATION.md manual evidence.
//
// Chain:
//   1) Authorization  — AuthorizationManager.requestAuthorization() / simulateStatusChange()
//   2) Scheduling     — ActivityScheduler.buildMonitoringConfiguration() + EventName constants
//   3) Shield apply   — ShieldManager.shieldApps() observable return value
//   4) Shield clear   — ShieldManager.clearAllShields() idempotency
//   5) Deauth cleanup — deauthorization triggers clearAllSettings + stopAllMonitoring
//
// Note: MockCleanupHandler is defined in AuthorizationManagerTests.swift (same test module).

final class ScreenTimeEngineUATStubs: XCTestCase {

    // MARK: - 1. Authorization

    // ENFC-01: AuthorizationManager must start in .notDetermined state (host platform guard).
    func testENFC01_authorizationManager_initialStatusIsNotDetermined() {
        let manager = AuthorizationManager()
        XCTAssertEqual(
            manager.currentStatus, .notDetermined,
            "ENFC-01: Authorization must start as notDetermined before requestAuthorization is called"
        )
    }

    // ENFC-01: requestAuthorization() must throw AuthorizationError on non-iOS host.
    // On iOS device, this call presents the FamilyControls system sheet.
    func testENFC01_requestAuthorization_throwsOnNonIOSHost() async {
        let manager = AuthorizationManager()
        do {
            try await manager.requestAuthorization()
            // On a real iOS device this line is reached after the sheet.
            // On macOS host, we expect an error — if reached here on macOS, fail.
            #if !os(iOS)
            XCTFail("ENFC-01: requestAuthorization() must throw on non-iOS host")
            #endif
        } catch let error as AuthorizationError {
            // Expected on macOS host — verify the correct error type is returned.
            XCTAssertTrue(
                error == .familyControlsUnavailable || error == .denied,
                "ENFC-01: Host platform must throw a documented AuthorizationError"
            )
        } catch {
            XCTFail("ENFC-01: Unexpected error type: \(error)")
        }
    }

    // ENFC-01: Deauthorization triggers cleanup chain via injected handler.
    // Uses MockCleanupHandler defined in AuthorizationManagerTests.swift.
    func testENFC01_deauthorization_triggersCleanupChain() {
        let mock = MockCleanupHandler()
        let manager = AuthorizationManager(cleanupHandler: mock)
        manager.simulateStatusChange(to: .denied)
        XCTAssertTrue(mock.clearAllSettingsCalled, "ENFC-01: deauth must trigger clearAllSettings")
        XCTAssertTrue(mock.stopMonitoringCalled, "ENFC-01: deauth must trigger stopAllMonitoring")
    }

    // ENFC-01: Non-deauth status transition must not trigger cleanup.
    func testENFC01_approvedTransition_doesNotTriggerCleanup() {
        let mock = MockCleanupHandler()
        let manager = AuthorizationManager(cleanupHandler: mock)
        manager.simulateStatusChange(to: .approved)
        XCTAssertFalse(mock.clearAllSettingsCalled, "ENFC-01: approved transition must not clear settings")
        XCTAssertFalse(mock.stopMonitoringCalled, "ENFC-01: approved transition must not stop monitoring")
    }

    // MARK: - 2. Scheduling / EventName constants

    // ENFC-01: EventName constants must be distinct, non-empty strings.
    func testENFC01_eventNameConstants_areDistinctAndNonEmpty() {
        let instagram = ScreenTimeEngine.EventName.instagramDailyLimit
        let tiktok    = ScreenTimeEngine.EventName.tiktokDailyLimit
        XCTAssertFalse(instagram.isEmpty, "ENFC-01: instagramDailyLimit constant must be non-empty")
        XCTAssertFalse(tiktok.isEmpty,    "ENFC-01: tiktokDailyLimit constant must be non-empty")
        XCTAssertNotEqual(instagram, tiktok, "ENFC-01: per-platform event names must be distinct")
    }

    // ENFC-01: buildMonitoringConfiguration maps per-platform limits to the correct event names.
    func testENFC01_buildMonitoringConfiguration_mapsThresholdsToEventNames() throws {
        let scheduler = ActivityScheduler()
        let config = try scheduler.buildMonitoringConfiguration(
            platformLimits: [.instagram: 45, .tiktok: 60]
        )
        let instagramKey = ScreenTimeEngine.EventName.instagramDailyLimit
        let tiktokKey    = ScreenTimeEngine.EventName.tiktokDailyLimit

        XCTAssertNotNil(config.events[instagramKey], "ENFC-01: instagram event must be present in config")
        XCTAssertNotNil(config.events[tiktokKey],    "ENFC-01: tiktok event must be present in config")
        XCTAssertEqual(config.events[instagramKey]?.threshold.minute, 45,
            "ENFC-01: instagram threshold must equal supplied limit")
        XCTAssertEqual(config.events[tiktokKey]?.threshold.minute, 60,
            "ENFC-01: tiktok threshold must equal supplied limit")
    }

    // ENFC-01: startMonitoring returns .noTokensSelected when no app tokens persisted.
    // Validates the enforcement guard that skips registration when no apps selected.
    func testENFC01_startMonitoring_returnsNoTokensSelectedWhenNoAppsChosen() async {
        let testSuite = "com.freesocial.test.enfc01-uat.\(UUID().uuidString)"
        let scheduler = ActivityScheduler(suiteName: testSuite)
        let result = await scheduler.startMonitoring(platformLimits: [.instagram: 30, .tiktok: 45])
        XCTAssertEqual(
            result, .noTokensSelected,
            "ENFC-01: startMonitoring must return .noTokensSelected when FamilyActivitySelectionStore is empty"
        )
    }

    // MARK: - 3. Shield apply path

    // ENFC-01: ShieldManager.shieldApps returns false for empty token set (explicit no-op).
    func testENFC01_shieldManager_emptyTokenSet_isNoOp() async {
        let manager = ShieldManager()
        let applied = await manager.shieldApps([])
        XCTAssertFalse(
            applied,
            "ENFC-01: shieldApps([]) must return false — empty token set must not write to ManagedSettingsStore"
        )
    }

    // MARK: - 4. Shield clear path

    // ENFC-01: clearAllShields is idempotent — callable when no shields active.
    func testENFC01_shieldManager_clearAllShields_isIdempotent() {
        let manager = ShieldManager()
        manager.clearAllShields()
        manager.clearAllShields()
        XCTAssertTrue(true, "ENFC-01: clearAllShields() must be idempotent — no crash on repeated calls")
    }
}
