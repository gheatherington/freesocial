import XCTest
@testable import PolicyStore

/// NB-02, NB-03 — PolicyRepository escalation and bypass telemetry persistence (DATA-03)
final class PolicyRepositoryPersistenceTests: XCTestCase {

    private let testSuiteName = "com.freesocial.tests.policyrepository"
    private var repo: PolicyRepository!

    override func setUp() {
        super.setUp()
        // Remove any previous test data before each test
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
        repo = PolicyRepository(suiteName: testSuiteName)
    }

    override func tearDown() {
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
        repo = nil
        super.tearDown()
    }

    // MARK: - Escalation level persistence

    // NB-02: Default escalation is .baseline when no data stored
    func testCurrentEscalationLevelDefaultsToBaseline() {
        XCTAssertEqual(repo.currentEscalationLevel(), .baseline)
    }

    // NB-02: Persisted escalation level is durable across instances
    func testEscalationLevelPersistedAcrossInstances() {
        repo.setEscalationLevel(.cooldown1)
        let repo2 = PolicyRepository(suiteName: testSuiteName)
        XCTAssertEqual(repo2.currentEscalationLevel(), .cooldown1)
    }

    // NB-02: All escalation levels round-trip correctly
    func testEscalationLevelRoundTripsAllValues() {
        for level in EscalationLevel.allCases {
            repo.setEscalationLevel(level)
            XCTAssertEqual(repo.currentEscalationLevel(), level, "Failed round-trip for \(level)")
        }
    }

    // NB-02: resetToBaseline sets escalation to .baseline
    func testResetToBaselineSetsEscalationToBaseline() {
        repo.setEscalationLevel(.lockdown)
        repo.resetToBaseline()
        XCTAssertEqual(repo.currentEscalationLevel(), .baseline)
    }

    // NB-02: Corrupt escalation data falls back to .baseline
    func testCorruptEscalationDataFallsBackToBaseline() {
        let defaults = UserDefaults(suiteName: testSuiteName)!
        defaults.set("not-valid-json".data(using: .utf8)!, forKey: "com.freesocial.policy.escalationLevel")
        let repo2 = PolicyRepository(suiteName: testSuiteName)
        XCTAssertEqual(repo2.currentEscalationLevel(), .baseline)
    }

    // MARK: - Bypass event persistence

    // NB-03: Bypass event count is 0 when no events stored
    func testBypassEventsEmptyWhenNoneRecorded() {
        XCTAssertEqual(repo.bypassEvents().count, 0)
    }

    // NB-03: recordBypassEvent appends and persists
    func testRecordBypassEventAppendsEvent() {
        let event = BypassEvent(escalationLevelAtTime: .baseline)
        repo.recordBypassEvent(event)
        XCTAssertEqual(repo.bypassEvents().count, 1)
        XCTAssertEqual(repo.bypassEvents().first?.id, event.id)
    }

    // NB-03: Multiple bypass events are ordered and durable across instances
    func testMultipleBypassEventsDurableAcrossInstances() {
        let e1 = BypassEvent(escalationLevelAtTime: .baseline)
        let e2 = BypassEvent(escalationLevelAtTime: .cooldown1)
        repo.recordBypassEvent(e1)
        repo.recordBypassEvent(e2)

        let repo2 = PolicyRepository(suiteName: testSuiteName)
        let events = repo2.bypassEvents()
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].id, e1.id)
        XCTAssertEqual(events[1].id, e2.id)
    }

    // NB-03: resetToBaseline clears bypass events
    func testResetToBaselineClearsBypassEvents() {
        repo.recordBypassEvent(BypassEvent(escalationLevelAtTime: .cooldown1))
        repo.resetToBaseline()
        XCTAssertEqual(repo.bypassEvents().count, 0)
    }

    // NB-03: Corrupt bypass event data falls back to empty array
    func testCorruptBypassEventsDataFallsBackToEmpty() {
        let defaults = UserDefaults(suiteName: testSuiteName)!
        defaults.set("not-valid-json".data(using: .utf8)!, forKey: "com.freesocial.policy.bypassEvents")
        let repo2 = PolicyRepository(suiteName: testSuiteName)
        XCTAssertEqual(repo2.bypassEvents().count, 0)
    }
}
