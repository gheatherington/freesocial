import XCTest
import ConsentManager
import PolicyStore

// ENFC-01: DeviceActivityMonitor threshold callback applies shields only when
// all guard conditions pass.
//
// These tests validate shouldApplyShields(for:selectionStore:elapsedSeconds:guardWindow:)
// — the pure logic helper extracted from DeviceActivityMonitorExtension — without
// requiring a live DeviceActivity runtime.
//
// Guard matrix:
//   - nil consent          → false (no shield apply)
//   - revoked consent      → false (no shield apply)
//   - no token selection   → false (no shield apply)
//   - premature event      → false (no shield apply, elapsed < guardWindow)
//   - all conditions valid → true  (shield apply)
final class DeviceActivityThresholdGuardTests: XCTestCase {

    /// Isolated suite names — avoid polluting App Group shared storage.
    private let consentSuite   = "com.freesocial.test.threshold-guard.consent"
    private let selectionSuite = "com.freesocial.test.threshold-guard.selection"

    /// Guard window used for all premature-event tests (30 seconds).
    private let guardWindow: TimeInterval = 30

    override func tearDown() {
        super.tearDown()
        UserDefaults(suiteName: consentSuite)?
            .removePersistentDomain(forName: consentSuite)
        UserDefaults(suiteName: selectionSuite)?
            .removePersistentDomain(forName: selectionSuite)
    }

    // MARK: - Consent gate

    // ENFC-01: Nil consent → no shield apply
    func testENFC01_nilConsent_doesNotApplyShields() {
        let consent   = ConsentStore(suiteName: consentSuite)
        let selection = FamilyActivitySelectionStore(suiteName: selectionSuite)
        // selection has no data, consent has no record
        let result = shouldApplyShields(
            for: consent,
            selectionStore: selection,
            elapsedSeconds: 60,
            guardWindow: guardWindow
        )
        XCTAssertFalse(result, "ENFC-01: nil consent must block shield apply")
    }

    // ENFC-01: Revoked consent → no shield apply
    func testENFC01_revokedConsent_doesNotApplyShields() {
        let consent   = ConsentStore(suiteName: consentSuite)
        let selection = FamilyActivitySelectionStore(suiteName: selectionSuite)
        var record = ConsentRecord(grantedAt: Date())
        record.isRevoked = true
        record.revokedAt = Date()
        consent.save(record)
        let result = shouldApplyShields(
            for: consent,
            selectionStore: selection,
            elapsedSeconds: 60,
            guardWindow: guardWindow
        )
        XCTAssertFalse(result, "ENFC-01: revoked consent must block shield apply")
    }

    // MARK: - Token selection gate

    // ENFC-01: Active consent but no token selection → no shield apply
    func testENFC01_noTokenSelection_doesNotApplyShields() {
        let consent   = ConsentStore(suiteName: consentSuite)
        let selection = FamilyActivitySelectionStore(suiteName: selectionSuite)
        let record = ConsentRecord(grantedAt: Date())
        consent.save(record)
        // selection store is empty — hasSelection == false
        let result = shouldApplyShields(
            for: consent,
            selectionStore: selection,
            elapsedSeconds: 60,
            guardWindow: guardWindow
        )
        XCTAssertFalse(result, "ENFC-01: no token selection must block shield apply")
    }

    // MARK: - Premature threshold event guard

    // ENFC-01: Elapsed < guardWindow → premature event, no shield apply
    func testENFC01_prematureThresholdEvent_doesNotApplyShields() {
        let consent   = ConsentStore(suiteName: consentSuite)
        let selection = FamilyActivitySelectionStore(suiteName: selectionSuite)
        let record = ConsentRecord(grantedAt: Date())
        consent.save(record)
        // Simulate selection data present in storage
        UserDefaults(suiteName: selectionSuite)?
            .set(Data([0x01]), forKey: "com.freesocial.policy.familyActivitySelection")
        let result = shouldApplyShields(
            for: consent,
            selectionStore: selection,
            elapsedSeconds: 10,      // 10s < 30s guardWindow
            guardWindow: guardWindow
        )
        XCTAssertFalse(result, "ENFC-01: premature threshold event (elapsed < guardWindow) must not apply shields")
    }

    // MARK: - Valid active path

    // ENFC-01: Consent active + selection present + elapsed >= guardWindow → shields apply
    func testENFC01_validConditions_appliesShields() {
        let consent   = ConsentStore(suiteName: consentSuite)
        let selection = FamilyActivitySelectionStore(suiteName: selectionSuite)
        let record = ConsentRecord(grantedAt: Date())
        consent.save(record)
        // Simulate selection data present in storage
        UserDefaults(suiteName: selectionSuite)?
            .set(Data([0x01]), forKey: "com.freesocial.policy.familyActivitySelection")
        let result = shouldApplyShields(
            for: consent,
            selectionStore: selection,
            elapsedSeconds: 60,      // 60s >= 30s guardWindow
            guardWindow: guardWindow
        )
        XCTAssertTrue(result, "ENFC-01: valid consent + selection + elapsed must allow shield apply")
    }
}
