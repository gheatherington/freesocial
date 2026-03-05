import XCTest
@testable import ConsentManager

/// UAT coverage for POL-02: Consent capture and withdrawal work as specified.
///
/// These tests replaced their XCTSkip stubs in Phase 3 (Plan 03-01).
/// Requirement IDs: POL-02, DATA-01, DATA-02.
final class ConsentManagerUATStubs: XCTestCase {
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "com.freesocial.uat.\(UUID().uuidString)"
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        suiteName = nil
        super.tearDown()
    }

    // MARK: - POL-02: Consent save/load round-trip

    /// POL-02 / DATA-01: A saved consent record is retrievable with its original values.
    func testConsentSaveAndLoadRoundTrip() throws {
        let store = ConsentStore(suiteName: suiteName)
        let record = ConsentRecord(id: UUID(), grantedAt: Date())
        store.save(record)

        let loaded = try XCTUnwrap(store.loadCurrent(), "Saved consent record must be retrievable")
        XCTAssertEqual(loaded.id, record.id)
        XCTAssertFalse(loaded.isRevoked)
        XCTAssertNil(loaded.revokedAt)
    }

    // MARK: - POL-02: Revocation mutation semantics

    /// POL-02 / DATA-01: revoke() sets isRevoked=true and populates revokedAt.
    func testRevocationMutationSemanticsIsRevokedAndRevokedAt() throws {
        let store = ConsentStore(suiteName: suiteName)
        store.save(ConsentRecord())
        store.revoke()

        let revoked = try XCTUnwrap(store.loadCurrent())
        XCTAssertTrue(revoked.isRevoked, "isRevoked must be true after revoke()")
        XCTAssertNotNil(revoked.revokedAt, "revokedAt must be set after revoke()")
    }

    // MARK: - POL-02: Revoked record still returned by loadCurrent

    /// POL-02 / DATA-01: Revoked records remain retrievable; nil is reserved for never-consented.
    func testRevokedRecordStillReturnedByLoadCurrent() throws {
        let store = ConsentStore(suiteName: suiteName)
        let record = ConsentRecord(id: UUID(), grantedAt: Date())
        store.save(record)
        store.revoke()

        let loaded = store.loadCurrent()
        XCTAssertNotNil(loaded, "loadCurrent() must return the record even when revoked")
        XCTAssertEqual(loaded?.id, record.id)
    }

    // MARK: - DATA-02: AuditLog append persistence

    /// DATA-02: Appended audit entries are stored and retrievable in insertion order.
    func testAuditLogAppendPersistsBehavior() throws {
        let log = AuditLog(suiteName: suiteName)
        log.append(AuditEntry(action: "consent.granted"))
        log.append(AuditEntry(action: "consent.revoked"))

        let entries = log.allEntries()
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].action, "consent.granted")
        XCTAssertEqual(entries[1].action, "consent.revoked")
    }
}
