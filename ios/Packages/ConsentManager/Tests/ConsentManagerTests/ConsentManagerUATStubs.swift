import XCTest
@testable import ConsentManager

final class ConsentManagerUATStubs: XCTestCase {

    // UAT: POL-02 — Consent capture and consent withdrawal work as specified
    func testConsentCaptureAndWithdrawalWork() throws {
        throw XCTSkip("UAT stub: POL-02 — pending ConsentStore.save() and revoke() implementation")
    }
}
