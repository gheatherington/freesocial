import XCTest
@testable import PolicyStore

final class PolicyStoreUATStubs: XCTestCase {

    private let testSuiteName = "com.freesocial.tests.policystoreuat"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
    }

    override func tearDown() {
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
        super.tearDown()
    }

    // UAT: NB-02 — Escalation states persist correctly and reset to baseline
    func testEscalationStatesTransitionCorrectlyAfterRepeatedBypass() {
        let repo = PolicyRepository(suiteName: testSuiteName)

        // Baseline is the initial state
        XCTAssertEqual(repo.currentEscalationLevel(), .baseline)

        // Escalation persists through all levels
        repo.setEscalationLevel(.cooldown1)
        XCTAssertEqual(repo.currentEscalationLevel(), .cooldown1)

        repo.setEscalationLevel(.lockdown)
        XCTAssertEqual(repo.currentEscalationLevel(), .lockdown)

        // Reset returns to baseline
        repo.resetToBaseline()
        XCTAssertEqual(repo.currentEscalationLevel(), .baseline)
    }

    // UAT: NB-03 — Bypass telemetry events recorded and linked to escalation state
    func testBypassTelemetryEventRecordedWithEscalationState() {
        let repo = PolicyRepository(suiteName: testSuiteName)

        // Record event at cooldown1
        repo.setEscalationLevel(.cooldown1)
        let event = BypassEvent(escalationLevelAtTime: .cooldown1)
        repo.recordBypassEvent(event)

        let events = repo.bypassEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.escalationLevelAtTime, .cooldown1)
        XCTAssertEqual(events.first?.id, event.id)
    }
}
