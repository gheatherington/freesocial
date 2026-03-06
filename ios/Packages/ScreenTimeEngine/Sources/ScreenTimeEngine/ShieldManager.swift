import Foundation

#if os(iOS)
import ManagedSettings
#endif

/// Manages application shielding using ManagedSettings framework.
///
/// Shields are applied via a named `ManagedSettingsStore` identified by
/// `ScreenTimeEngine.managedStoreIdentifier`. The named store ensures the extension
/// and main app target the same shield container.
///
/// - SeeAlso: `ScreenTimeEngine.managedStoreIdentifier`
public final class ShieldManager {

    public init() {}

    // MARK: - Apply Shields

    /// Applies content shields to the specified application tokens.
    ///
    /// - Parameter tokens: Set of `ApplicationToken` values identifying apps to shield.
    ///   On macOS (package test host), this method is compiled but the `#if os(iOS)` body
    ///   is excluded — the no-op return path is always taken.
    /// - Returns: `true` when shields were written to the ManagedSettingsStore,
    ///   `false` when the token set was empty (explicit no-op path).
    @discardableResult
    public func shieldApps(_ tokens: Set<ApplicationToken>) async -> Bool {
        guard !tokens.isEmpty else {
            // Empty token set: explicit no-op. Caller can observe false to distinguish
            // from a successful write.
            return false
        }

        #if os(iOS)
        let store = ManagedSettingsStore(named: ManagedSettingsStore.Name(ScreenTimeEngine.managedStoreIdentifier))
        store.shield.applications = tokens
        #endif

        return true
    }

    // MARK: - Clear Shields

    /// Removes all application shields from the named ManagedSettingsStore.
    ///
    /// Safe to call when no shields are active (idempotent).
    public func clearAllShields() {
        #if os(iOS)
        let store = ManagedSettingsStore(named: ManagedSettingsStore.Name(ScreenTimeEngine.managedStoreIdentifier))
        store.shield.applications = nil
        #endif
    }
}

// MARK: - ApplicationToken type alias for non-iOS hosts

#if !os(iOS)
/// Placeholder to allow ShieldManager to compile on macOS (SPM test host).
/// On iOS, the real `ManagedSettings.ApplicationToken` is used.
public typealias ApplicationToken = AnyHashable
#endif
