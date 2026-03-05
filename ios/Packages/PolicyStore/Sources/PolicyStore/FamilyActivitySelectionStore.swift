import Foundation

#if os(iOS)
import FamilyControls
#endif

/// Persists the user's selected FamilyActivity token set to App Group shared UserDefaults.
/// FamilyControls-dependent APIs are compile-guarded for macOS `swift test` compatibility.
public struct FamilyActivitySelectionStore {
    private let defaults: UserDefaults

    private enum Keys {
        static let selection = "com.freesocial.policy.familyActivitySelection"
    }

    /// Initializes with the shared App Group defaults.
    public init() {
        if let shared = UserDefaults(suiteName: AppGroup.suiteName) {
            self.defaults = shared
        } else {
            assertionFailure(
                "App Group '\(AppGroup.suiteName)' is unavailable — " +
                "FamilyActivitySelection persistence will fail. " +
                "Verify the App Group entitlement is configured."
            )
            self.defaults = .standard
        }
    }

    /// Designated initializer for tests — accepts an explicit suiteName.
    public init(suiteName: String) {
        if let shared = UserDefaults(suiteName: suiteName) {
            self.defaults = shared
        } else {
            assertionFailure("UserDefaults suiteName '\(suiteName)' is unavailable.")
            self.defaults = .standard
        }
    }

    // MARK: - State query (cross-platform)

    /// Returns true when a persisted selection exists in storage.
    public var hasSelection: Bool {
        defaults.data(forKey: Keys.selection) != nil
    }

    /// Removes any persisted selection from storage.
    public func clear() {
        defaults.removeObject(forKey: Keys.selection)
    }

    // MARK: - FamilyControls persistence (iOS/tvOS only)

#if os(iOS)
    /// Persists a FamilyActivitySelection using JSONEncoder.
    /// Call from the main app after FamilyActivityPicker is dismissed.
    public func save(_ selection: FamilyControls.FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: Keys.selection)
        }
    }

    /// Loads the previously persisted FamilyActivitySelection.
    /// Returns nil on missing or corrupt data.
    public func load() -> FamilyControls.FamilyActivitySelection? {
        guard let data = defaults.data(forKey: Keys.selection) else { return nil }
        return try? JSONDecoder().decode(FamilyControls.FamilyActivitySelection.self, from: data)
    }
#endif
}
