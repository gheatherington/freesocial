import XCTest
@testable import ScreenTimeEngine

// MARK: - Protocol seam for testability

/// Wrapper allowing tests to inject mock authorization behavior.
/// Real implementation uses FamilyControls under compile guard.
protocol AuthorizationStatusObserver: AnyObject {
    func authorizationStatusDidChange(to status: AuthorizationStatus)
}

// MARK: - AuthorizationManager tests (Task 1 + Task 2)

final class AuthorizationManagerTests: XCTestCase {

    // MARK: Task 1: Request flow and status surface

    /// ENFC-01: requestAuthorization must be callable and not crash on non-iOS host
    func testRequestAuthorizationDoesNotThrowOnHostPlatform() async {
        let manager = AuthorizationManager()
        do {
            try await manager.requestAuthorization()
            // Success path: no throw on macOS host where FamilyControls is unavailable
        } catch {
            // If it throws it should be a documented FamilyControlsUnavailableError, not a crash
            XCTAssertTrue(
                error is AuthorizationError,
                "Unexpected error type: \(error). Expected AuthorizationError on platforms without FamilyControls."
            )
        }
    }

    /// Status surface: currentStatus must be readable without crashing
    func testCurrentStatusIsReadable() {
        let manager = AuthorizationManager()
        // Just accessing the property must not crash; default must be notDetermined on macOS host
        let status = manager.currentStatus
        XCTAssertEqual(status, .notDetermined, "Initial status must be .notDetermined on non-iOS host")
    }

    // MARK: Task 2: Deauthorization observer and cleanup

    /// Deauthorization must trigger cleanup (clearAllSettings + stop monitoring)
    func testDeauthorizationTriggersCleaner() {
        let cleaner = MockCleanupHandler()
        let manager = AuthorizationManager(cleanupHandler: cleaner)

        // Simulate deauthorization transition
        manager.simulateStatusChange(to: .denied)

        XCTAssertTrue(cleaner.clearAllSettingsCalled, "clearAllSettings must be called on deauthorization")
        XCTAssertTrue(cleaner.stopMonitoringCalled, "stopMonitoring must be called on deauthorization")
    }

    /// Non-deauth transitions must NOT trigger cleanup
    func testNonDeauthTransitionDoesNotTriggerCleaner() {
        let cleaner = MockCleanupHandler()
        let manager = AuthorizationManager(cleanupHandler: cleaner)

        // Simulate transition that is not a revocation
        manager.simulateStatusChange(to: .approved)

        XCTAssertFalse(cleaner.clearAllSettingsCalled, "clearAllSettings must NOT be called for non-deauth transitions")
        XCTAssertFalse(cleaner.stopMonitoringCalled, "stopMonitoring must NOT be called for non-deauth transitions")
    }

    /// Cleanup must be idempotent — calling multiple times must not crash
    func testCleanupIsIdempotent() {
        let cleaner = MockCleanupHandler()
        let manager = AuthorizationManager(cleanupHandler: cleaner)

        manager.simulateStatusChange(to: .denied)
        manager.simulateStatusChange(to: .denied)
        manager.simulateStatusChange(to: .denied)

        // Should still just reflect that cleanup ran — no crash expected
        XCTAssertTrue(cleaner.clearAllSettingsCalled)
        XCTAssertTrue(cleaner.stopMonitoringCalled)
    }
}

// MARK: - Mock helpers

final class MockCleanupHandler: AuthorizationCleanupHandler {
    var clearAllSettingsCalled = false
    var stopMonitoringCalled = false

    func clearAllSettings() {
        clearAllSettingsCalled = true
    }

    func stopAllMonitoring() {
        stopMonitoringCalled = true
    }
}
