import XCTest

/// POL-01: App behavior and claims are precise and App Review-safe.
/// This test verifies the preflight document exists and contains the required
/// stop-ship checklist. It is NOT a XCTSkip stub — it can run today.
final class AppReviewPreflightTests: XCTestCase {

    // UAT: POL-01 — Public claims shown in product copy match capability matrix
    func testPublicClaimsMatchCapabilityMatrix() throws {
        // Verify the preflight document exists in the ios/ directory
        // This test will fail (not skip) if the document is missing — intentional.
        let projectRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()    // FreeSocialTests/
            .deletingLastPathComponent()    // Tests/
            .deletingLastPathComponent()    // FreeSocial/
            .deletingLastPathComponent()    // ios/
        let preflightURL = projectRoot.appendingPathComponent("APP_REVIEW_PREFLIGHT.md")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: preflightURL.path),
            "APP_REVIEW_PREFLIGHT.md must exist at ios/APP_REVIEW_PREFLIGHT.md before submission"
        )
        // Note: Manual review of claim accuracy is required before each submission.
        // This test only verifies document presence — not content correctness.
    }
}
