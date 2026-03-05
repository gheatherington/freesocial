import XCTest
@testable import ConsentManager

/// Tests for AuditLog encoded-array persistence via App Group UserDefaults.
/// DATA-02: Audit entries survive process restarts and are shareable across processes.
final class AuditLogPersistenceTests: XCTestCase {
    private var suiteName: String!
    private var log: AuditLog!

    override func setUp() {
        super.setUp()
        suiteName = "com.freesocial.test.\(UUID().uuidString)"
        log = AuditLog(suiteName: suiteName)
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        log = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - append / read round-trip

    /// DATA-02: Appended entries are retrievable from persistent storage.
    func testAppendSingleEntryIsPersisted() throws {
        let entry = AuditEntry(timestamp: Date(), action: "consent.granted")
        log.append(entry)

        let entries = log.allEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.action, "consent.granted")
    }

    /// Multiple appends accumulate in insertion order.
    func testAppendMultipleEntriesPreservesOrder() throws {
        log.append(AuditEntry(action: "consent.granted"))
        log.append(AuditEntry(action: "consent.revoked"))
        log.append(AuditEntry(action: "consent.granted"))

        let entries = log.allEntries()
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[0].action, "consent.granted")
        XCTAssertEqual(entries[1].action, "consent.revoked")
        XCTAssertEqual(entries[2].action, "consent.granted")
    }

    /// allEntries() returns empty array when nothing has been appended.
    func testAllEntriesReturnsEmptyWhenNoEntriesExist() {
        XCTAssertEqual(log.allEntries().count, 0)
    }

    /// DATA-02: A second AuditLog instance using the same suite reads persisted entries.
    func testEntriesPersistedAcrossInstances() throws {
        log.append(AuditEntry(action: "consent.granted"))

        let secondLog = AuditLog(suiteName: suiteName)
        let entries = secondLog.allEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.action, "consent.granted")
    }

    /// Corrupt payload is treated as empty — no crash, no data loss from future appends.
    func testCorruptPayloadTreatedAsEmpty() throws {
        // Write garbage bytes to the storage key.
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(Data("not-json".utf8), forKey: "com.freesocial.consent.auditLog")

        // Appending to a corrupt store must not crash and must produce 1 entry.
        let entry = AuditEntry(action: "consent.granted")
        log.append(entry)

        let entries = log.allEntries()
        XCTAssertEqual(entries.count, 1, "Corrupt existing payload must be treated as empty")
    }
}
