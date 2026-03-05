import XCTest
@testable import ConsentManager

/// Tests for ConsentStore App Group persistence with locked revocation semantics.
/// DATA-01: Consent lifecycle state is durable and shareable across processes.
final class ConsentStorePersistenceTests: XCTestCase {
    private var suiteName: String!
    private var store: ConsentStore!

    override func setUp() {
        super.setUp()
        // Use a unique suite name per test run to avoid cross-test state leakage.
        suiteName = "com.freesocial.test.\(UUID().uuidString)"
        store = ConsentStore(suiteName: suiteName)
    }

    override func tearDown() {
        // Clean up the test suite container.
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        store = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - save / loadCurrent round-trip

    /// DATA-01: ConsentRecord survives a save/load round-trip via UserDefaults.
    func testSaveAndLoadCurrentRoundTrip() throws {
        let original = ConsentRecord(id: UUID(), grantedAt: Date())
        store.save(original)

        let loaded = try XCTUnwrap(store.loadCurrent(), "Expected loadCurrent() to return saved record")
        XCTAssertEqual(loaded.id, original.id)
        XCTAssertEqual(loaded.isRevoked, false)
        XCTAssertNil(loaded.revokedAt)
    }

    /// loadCurrent() returns nil when no record has been saved.
    func testLoadCurrentReturnsNilWhenNoRecordSaved() {
        XCTAssertNil(store.loadCurrent(), "Expected nil for empty store")
    }

    // MARK: - revoke semantics

    /// DATA-01: revoke() sets isRevoked=true and revokedAt on the stored record.
    func testRevokeMarksRecordAsRevoked() throws {
        let original = ConsentRecord(id: UUID(), grantedAt: Date())
        store.save(original)

        store.revoke()

        let loaded = try XCTUnwrap(store.loadCurrent(), "Expected loadCurrent() to return record after revoke()")
        XCTAssertTrue(loaded.isRevoked, "isRevoked must be true after revoke()")
        XCTAssertNotNil(loaded.revokedAt, "revokedAt must be set after revoke()")
    }

    /// DATA-01: revoked record is still retrievable (nil only means never consented).
    func testLoadCurrentReturnsRevokedRecord() throws {
        let original = ConsentRecord(id: UUID(), grantedAt: Date())
        store.save(original)
        store.revoke()

        let loaded = store.loadCurrent()
        XCTAssertNotNil(loaded, "loadCurrent() must return the record even when revoked")
        XCTAssertEqual(loaded?.id, original.id, "Loaded record must match original id")
    }

    /// revoke() is a no-op when no record exists — must not crash.
    func testRevokeIsNoOpWhenNoRecord() {
        XCTAssertNil(store.loadCurrent())
        store.revoke() // Must not crash or throw
        XCTAssertNil(store.loadCurrent(), "loadCurrent() must still return nil after no-op revoke()")
    }

    /// DATA-01: A second save overwrites the previous record.
    func testSaveOverwritesPreviousRecord() throws {
        let first = ConsentRecord(id: UUID(), grantedAt: Date())
        store.save(first)

        let second = ConsentRecord(id: UUID(), grantedAt: Date())
        store.save(second)

        let loaded = try XCTUnwrap(store.loadCurrent())
        XCTAssertEqual(loaded.id, second.id, "loadCurrent() must return the most recently saved record")
    }
}
