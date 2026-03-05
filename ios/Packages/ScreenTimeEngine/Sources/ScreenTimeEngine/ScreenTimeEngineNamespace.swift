import Foundation

// MARK: - ScreenTimeEngine Namespace Constants
// Single source of truth for monitoring/store identifiers.
// Centralizing here prevents string drift across modules.

public enum ScreenTimeEngine {
    /// Identifier for the daily monitoring activity registered with DeviceActivity.
    public static let dailyActivityName = "freesocial.daily"

    /// Named ManagedSettingsStore identifier used by the extension shield path.
    /// Must match across main app and extension targets.
    public static let managedStoreIdentifier = "freesocial.shields"

    /// Stable DeviceActivityEvent.Name raw value strings.
    /// Centralizing here prevents string drift between ActivityScheduler and the extension callback.
    public enum EventName {
        /// Threshold event delivered when the Instagram daily usage limit is reached.
        public static let instagramDailyLimit = "freesocial.event.instagram.daily"
        /// Threshold event delivered when the TikTok daily usage limit is reached.
        public static let tiktokDailyLimit    = "freesocial.event.tiktok.daily"
    }
}

// MARK: - AuthorizationStatus
// Platform-agnostic mirror of FamilyControls.AuthorizationStatus.
// Allows host (macOS) tests to exercise status transitions without FamilyControls.

public enum AuthorizationStatus: Equatable {
    /// User has not yet been asked.
    case notDetermined
    /// Authorization granted.
    case approved
    /// Authorization denied or revoked.
    case denied
}

// MARK: - AuthorizationError

public enum AuthorizationError: Error {
    /// FamilyControls framework is not available on this platform.
    case familyControlsUnavailable
    /// The authorization request was rejected by the system or user.
    case denied
}

// MARK: - AuthorizationCleanupHandler
// Protocol seam allowing deauthorization cleanup to be tested without FamilyControls.

public protocol AuthorizationCleanupHandler: AnyObject {
    /// Called when authorization is revoked; must clear all ManagedSettings shields.
    func clearAllSettings()
    /// Called when authorization is revoked; must stop active DeviceActivity monitoring.
    func stopAllMonitoring()
}
