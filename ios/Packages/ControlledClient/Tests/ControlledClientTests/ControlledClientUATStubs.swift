import XCTest
@testable import ControlledClient

final class ControlledClientUATStubs: XCTestCase {

    // UAT: CC-01 — User consumes finite batches with no infinite scroll
    func testFiniteBatchBoundaryInterruptsScrolling() throws {
        throw XCTSkip("UAT stub: CC-01 — pending FeedView implementation")
    }

    // UAT: CC-02 — Supported communication pathway works; unsupported falls back cleanly
    func testUnsupportedPathwayFallsBackCleanly() throws {
        throw XCTSkip("UAT stub: CC-02 — pending SocialProvider pathway matrix")
    }

    // UAT: CC-03 — Blocked feed attempts show intervention and cooldown messaging
    func testBlockedFeedShowsInterventionWithCooldown() throws {
        throw XCTSkip("UAT stub: CC-03 — pending InterventionView implementation")
    }

    // UAT: POL-03 — Limitation disclosures are visible in onboarding and blocked states
    func testLimitationDisclosuresVisibleInOnboardingAndBlockedState() throws {
        throw XCTSkip("UAT stub: POL-03 — pending onboarding flow and InterventionView content")
    }
}
