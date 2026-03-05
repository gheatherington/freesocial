import XCTest
import ConsentManager

// DATA-02: Extension enforces consent gate before recording bypass telemetry.
// These tests validate the boundary behavior of shouldRecordBypassEvent(for:)
// — the pure logic helper extracted from DeviceActivityMonitorExtension.
final class DeviceActivityMonitorConsentGateTests: XCTestCase {

    /// Isolated suite name for tests — avoids polluting App Group shared storage.
    private let testSuiteName = "com.freesocial.test.dam-consent-gate"

    override func tearDown() {
        super.tearDown()
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
    }

    // DATA-02: Nil consent → bypass write path must NOT be invoked
    func testDATA02_nilConsent_doesNotAllowBypassRecord() {
        let store = ConsentStore(suiteName: testSuiteName)
        // No record saved — loadCurrent() returns nil
        XCTAssertFalse(
            shouldRecordBypassEvent(for: store),
            "DATA-02: shouldRecordBypassEvent must return false when no consent record exists"
        )
    }

    // DATA-02: Revoked consent → bypass write path must NOT be invoked
    func testDATA02_revokedConsent_doesNotAllowBypassRecord() {
        let store = ConsentStore(suiteName: testSuiteName)
        var record = ConsentRecord(grantedAt: Date())
        record.isRevoked = true
        record.revokedAt = Date()
        store.save(record)
        XCTAssertFalse(
            shouldRecordBypassEvent(for: store),
            "DATA-02: shouldRecordBypassEvent must return false when consent is revoked"
        )
    }

    // DATA-02: Active consent → bypass write path MUST be invoked
    func testDATA02_activeConsent_allowsBypassRecord() {
        let store = ConsentStore(suiteName: testSuiteName)
        let record = ConsentRecord(grantedAt: Date())
        store.save(record)
        XCTAssertTrue(
            shouldRecordBypassEvent(for: store),
            "DATA-02: shouldRecordBypassEvent must return true when consent is active (isRevoked == false)"
        )
    }
}
