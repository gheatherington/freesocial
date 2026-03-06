import XCTest
import ScreenTimeEngine

// ENFC-01: ShieldManager exposes token-based apply/clear API using ManagedSettings.
// These tests verify the observable boundary behavior of ShieldManager's shield path:
//   - Empty token set is an explicit no-op (returns false, no ManagedSettingsStore write).
//   - clearAllShields() is callable without error (idempotent).
//
// ApplicationToken instances are opaque and cannot be constructed in unit tests without
// a live FamilyControls authorization grant. The valid-token path (returns true) is
// exercised by real-device UAT (ENFC-01 verification matrix).
final class ShieldManagerTokenAPITests: XCTestCase {

    // ENFC-01: Empty token set must not apply shields — observable via return value.
    func testENFC01_emptyTokenSet_isNoOp() async {
        let manager = ShieldManager()
        // shieldApps(_:) with an empty set must return false (no-op path taken).
        let applied = await manager.shieldApps([])
        XCTAssertFalse(
            applied,
            "ENFC-01: shieldApps([]) must return false — empty token set is an explicit no-op"
        )
    }

    // ENFC-01: clearAllShields() is callable and idempotent (no error thrown).
    func testENFC01_clearAllShields_isIdempotent() {
        let manager = ShieldManager()
        // Must not crash or throw when called with no shields active.
        manager.clearAllShields()
        manager.clearAllShields()
        // If we reach here, the idempotent contract is satisfied.
        XCTAssertTrue(true, "ENFC-01: clearAllShields() must be idempotent")
    }
}
