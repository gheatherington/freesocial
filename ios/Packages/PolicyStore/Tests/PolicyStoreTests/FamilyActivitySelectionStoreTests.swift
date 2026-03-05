import XCTest
@testable import PolicyStore

/// DATA-03 — FamilyActivitySelectionStore persistence contract
/// On macOS (swift test), FamilyControls is unavailable so only the
/// non-FamilyControls portions of the API are tested here.
final class FamilyActivitySelectionStoreTests: XCTestCase {

    private let testSuiteName = "com.freesocial.tests.familyactivityselectionstore"
    private var store: FamilyActivitySelectionStore!

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
        store = FamilyActivitySelectionStore(suiteName: testSuiteName)
    }

    override func tearDown() {
        UserDefaults(suiteName: testSuiteName)?.removePersistentDomain(forName: testSuiteName)
        store = nil
        super.tearDown()
    }

    // DATA-03: hasSelection returns false when nothing is stored
    func testHasSelectionFalseWhenEmpty() {
        XCTAssertFalse(store.hasSelection)
    }

    // DATA-03: clear removes stored selection
    func testClearRemovesSelection() {
        // Store a raw data blob representing a hypothetical saved selection
        let defaults = UserDefaults(suiteName: testSuiteName)!
        defaults.set(Data([0x01, 0x02, 0x03]), forKey: "com.freesocial.policy.familyActivitySelection")
        XCTAssertTrue(store.hasSelection)
        store.clear()
        XCTAssertFalse(store.hasSelection)
    }

    // DATA-03: clear is idempotent on empty store
    func testClearIsIdempotentWhenEmpty() {
        store.clear()
        XCTAssertFalse(store.hasSelection)
    }
}
